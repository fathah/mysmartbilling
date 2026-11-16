<?php
// Integration checks use disposable databases on the configured MySQL server.
if (PHP_SAPI !== 'cli') {
    http_response_code(404);
    exit;
}

require_once __DIR__ . '/../database/Migrator.php';

function check(bool $condition, string $message): void
{
    if (!$condition) {
        throw new RuntimeException($message);
    }
}

$cfg = require __DIR__ . '/../config.php';
$options = [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION, PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC];
$server = new PDO("mysql:host={$cfg['host']};charset={$cfg['charset']}", $cfg['username'], $cfg['password'], $options);
$name = 'fora_migration_test_' . bin2hex(random_bytes(6));
$directory = sys_get_temp_dir() . '/' . $name;
mkdir($directory);
$server->exec("CREATE DATABASE `{$name}` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci");
try {
    $pdo = new PDO("mysql:host={$cfg['host']};dbname={$name};charset={$cfg['charset']}", $cfg['username'], $cfg['password'], $options);
    $runner = new Migrator($pdo);
    $runner->deploy();
    $count = count(glob(__DIR__ . '/../database/migrations/*.sql'));
    check((int) $pdo->query('SELECT COUNT(*) FROM schema_migrations')->fetchColumn() === $count, 'Full migration history missing.');
    check((int) $pdo->query("SELECT COUNT(*) FROM schema_migrations WHERE status <> 'applied'")->fetchColumn() === 0, 'Migration did not finish.');
    check($pdo->query("SHOW COLUMNS FROM mobile_purchase_order_lines LIKE 'brand'")->fetch() !== false, 'Purchase order dependency order failed.');
    check($pdo->query("SHOW COLUMNS FROM grocery_customers LIKE 'building_flat'")->fetch() !== false, 'Grocery dependency order failed.');
    $pdo->exec("INSERT INTO mobile_inventory (company_id, inventory_type, item_name, model, model_year, imei_number, purchase_amount, sale_amount, profit_amount) SELECT id, 'new', 'Test device', 'Test', 2026, 'TEST-IMEI', 10, 20, 123 FROM companies LIMIT 1");
    $runner->deploy();
    check((float) $pdo->query('SELECT profit_amount FROM mobile_inventory LIMIT 1')->fetchColumn() === 123.0, 'Completed data migration ran twice.');
    check((int) $pdo->query('SELECT COUNT(*) FROM schema_migrations')->fetchColumn() === $count, 'History duplicated.');
    echo "PASS full fresh install, dependency order, repeat deploy, data preserved\n";

    $concurrentName = $name . '_concurrent';
    $server->exec("CREATE DATABASE `{$concurrentName}` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci");
    try {
        $worker = <<<'WORKER'
require $argv[1] . '/database/Migrator.php';
$cfg = require $argv[1] . '/config.php';
$pdo = new PDO("mysql:host={$cfg['host']};dbname={$argv[2]};charset={$cfg['charset']}", $cfg['username'], $cfg['password'], [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]);
(new Migrator($pdo))->deploy();
WORKER;
        $processes = [];
        for ($index = 0; $index < 2; $index++) {
            $pipes = [];
            $process = proc_open([PHP_BINARY, '-r', $worker, dirname(__DIR__), $concurrentName], [1 => ['pipe', 'w'], 2 => ['pipe', 'w']], $pipes);
            check(is_resource($process), 'Could not start concurrent migration worker.');
            $processes[] = [$process, $pipes];
        }
        foreach ($processes as [$process, $pipes]) {
            $output = stream_get_contents($pipes[1]) . stream_get_contents($pipes[2]);
            fclose($pipes[1]);
            fclose($pipes[2]);
            check(proc_close($process) === 0, 'Concurrent migration failed. ' . $output);
        }
        $concurrent = new PDO("mysql:host={$cfg['host']};dbname={$concurrentName};charset={$cfg['charset']}", $cfg['username'], $cfg['password'], $options);
        check((int) $concurrent->query('SELECT COUNT(*) FROM schema_migrations')->fetchColumn() === $count, 'Concurrent deployments duplicated or skipped history.');
        check((int) $concurrent->query("SELECT COUNT(*) FROM schema_migrations WHERE status <> 'applied'")->fetchColumn() === 0, 'Concurrent deployments left an unfinished migration.');
        echo "PASS concurrent fresh deployments\n";
    } finally {
        $server->exec("DROP DATABASE `{$concurrentName}`");
    }

    // Exercise partial DDL failure and both explicit recovery paths.
    $first = $directory . '/001_first.sql';
    $second = $directory . '/002_second.sql';
    file_put_contents($first, 'CREATE TABLE sample (id INT PRIMARY KEY); INSERT INTO sample VALUES (1);');
    file_put_contents($second, 'ALTER TABLE sample ADD COLUMN note VARCHAR(50); INSERT INTO missing_table VALUES (1);');
    // Use an isolated empty schema for the small recovery fixtures.
    $fixtureName = $name . '_fixture';
    $server->exec("CREATE DATABASE `{$fixtureName}` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci");
    try {
        $fixture = new PDO("mysql:host={$cfg['host']};dbname={$fixtureName};charset={$cfg['charset']}", $cfg['username'], $cfg['password'], $options);
        $runner = new Migrator($fixture, $directory);
        try {
            $runner->deploy();
            throw new LogicException('Expected SQL failure.');
        } catch (RuntimeException $error) {
            check(str_contains($error->getMessage(), '002_second.sql failed'), 'Unexpected migration error.');
        }
        check($fixture->query("SELECT status FROM schema_migrations WHERE migration_name='002_second.sql'")->fetchColumn() === 'failed', 'Partial SQL failure was not recorded.');
        check($fixture->query("SHOW COLUMNS FROM sample LIKE 'note'")->fetch() !== false, 'Fixture did not partially commit DDL.');
        try {
            $runner->deploy();
            throw new LogicException('Expected unresolved failure to block deploy.');
        } catch (RuntimeException $error) {
            check(str_contains($error->getMessage(), 'is failed'), 'Failed migration retried.');
        }
        $fixture->exec('ALTER TABLE sample DROP COLUMN note');
        $runner->resolve('002_second.sql', 'rolled-back');
        $fixture->exec('CREATE TABLE missing_table (id INT PRIMARY KEY)');
        $runner->deploy();
        check((int) $fixture->query('SELECT COUNT(*) FROM missing_table')->fetchColumn() === 1, 'Retry after repair failed.');
        $fixture->exec("UPDATE schema_migrations SET status='running' WHERE migration_name='002_second.sql'");
        try {
            $runner->deploy();
            throw new LogicException('Expected interrupted migration to block deploy.');
        } catch (RuntimeException $error) {
            check(str_contains($error->getMessage(), 'is running'), 'Interrupted migration retried.');
        }
        $runner->resolve('002_second.sql', 'applied');
        $runner->deploy();
        echo "PASS partial DDL failure, interrupted run, repair and retry, mark applied\n";

        file_put_contents($first, "\n-- edited\n", FILE_APPEND);
        try {
            $runner->deploy();
            throw new LogicException('Expected checksum failure.');
        } catch (RuntimeException $error) {
            check(str_contains($error->getMessage(), 'was modified'), 'Checksum drift undetected.');
        }
        echo "PASS checksum drift\n";
        file_put_contents($first, 'CREATE TABLE sample (id INT PRIMARY KEY); INSERT INTO sample VALUES (1);');
        file_put_contents($directory . '/000_backdated.sql', 'SELECT 1;');
        try {
            (new Migrator($fixture, $directory))->deploy();
            throw new LogicException('Expected order failure.');
        } catch (RuntimeException $error) {
            check(str_contains($error->getMessage(), 'order changed'), 'Backdated migration undetected.');
        }
        unlink($directory . '/000_backdated.sql');
        echo "PASS backdated migration detection\n";
        $fixture->exec('DROP TABLE schema_migrations');
        try {
            $runner->deploy();
            throw new LogicException('Expected untracked database protection.');
        } catch (RuntimeException $error) {
            check(str_contains($error->getMessage(), 'no migration history'), 'Untracked schema was replayed.');
        }
        $runner->baseline('001_first.sql');
        $runner->resolve('002_second.sql', 'applied'); // Must reject resolving a pending file.
        throw new LogicException('Expected pending resolution to fail.');
    } catch (RuntimeException $error) {
        check(str_contains($error->getMessage(), 'Only a failed or interrupted'), 'Unexpected baseline error.');
        check($fixture->query("SELECT status FROM schema_migrations WHERE migration_name='001_first.sql'")->fetchColumn() === 'baselined', 'Baseline not recorded.');
        check($fixture->query("SELECT COUNT(*) FROM schema_migrations WHERE migration_name='002_second.sql'")->fetchColumn() == 0, 'Baseline skipped pending migration.');
        echo "PASS legacy baseline preserves pending files and rejects pending resolution\n";
    } finally {
        $server->exec("DROP DATABASE `{$fixtureName}`");
    }
} finally {
    $server->exec("DROP DATABASE `{$name}`");
    foreach (glob($directory . '/*.sql') as $file) {
        unlink($file);
    }
    rmdir($directory);
}
