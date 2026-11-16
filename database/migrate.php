<?php

if (PHP_SAPI !== 'cli') {
    http_response_code(404);
    exit;
}

require_once __DIR__ . '/../database.php';
require_once __DIR__ . '/Migrator.php';

try {
    $command = $argv[1] ?? 'deploy';
    if (!in_array($command, ['init', 'deploy', 'status', 'baseline', 'resolve'], true)) {
        throw new InvalidArgumentException('Use init, deploy, status, baseline <file.sql>, or resolve <file.sql> applied|rolled-back.');
    }
    if ($command === 'init') {
        $cfg = require __DIR__ . '/../config.php';
        $server = new PDO("mysql:host={$cfg['host']};charset={$cfg['charset']}", $cfg['username'], $cfg['password'], [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]);
        $database = str_replace('`', '``', $cfg['database']);
        $server->exec("CREATE DATABASE IF NOT EXISTS `{$database}` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci");
    }
    $migrator = new Migrator(db());
    switch ($command) {
        case 'init':
        case 'deploy':
            $migrator->deploy();
            echo "Database migrations are up to date.\n";
            break;
        case 'status':
            $last = 'none';
            foreach ($migrator->status() as $row) {
                echo $row['status'] . "\t" . $row['migration_name'] . "\n";
                if (in_array($row['status'], ['applied', 'baselined'], true)) {
                    $last = $row['migration_name'];
                }
            }
            echo "Last completed migration: {$last}\n";
            break;
        case 'baseline':
            $migrator->baseline($argv[2] ?? '');
            echo "Existing migration history recorded.\n";
            break;
        case 'resolve':
            $migrator->resolve($argv[2] ?? '', $argv[3] ?? '');
            echo "Migration resolution recorded.\n";
            break;
    }
} catch (Throwable $error) {
    fwrite(STDERR, $error->getMessage() . "\n");
    if ($error->getPrevious()) {
        fwrite(STDERR, $error->getPrevious()->getMessage() . "\n");
    }
    exit(1);
}
