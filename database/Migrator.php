<?php

final class Migrator
{
    private array $files;
    private string $lockName;

    public function __construct(private PDO $pdo, ?string $directory = null)
    {
        $directory ??= __DIR__ . '/migrations';
        $paths = glob($directory . '/*.sql');
        if ($paths === false || $paths === []) {
            throw new RuntimeException('No migration files found.');
        }
        $this->files = [];
        foreach ($paths as $path) {
            $this->files[basename($path)] = $path;
        }
        // Historical filenames predate some of their dependencies.
        $legacyOrder = require __DIR__ . '/migration_order.php';
        $ordered = [];
        foreach ($legacyOrder as $name) {
            if ($directory === __DIR__ . '/migrations' && !isset($this->files[$name])) {
                throw new RuntimeException("Missing migration file {$name}.");
            }
            if (isset($this->files[$name])) {
                $ordered[$name] = $this->files[$name];
                unset($this->files[$name]);
            }
        }
        ksort($this->files, SORT_STRING);
        $this->files = $ordered + $this->files;
        $database = $pdo->query('SELECT DATABASE()')->fetchColumn();
        $this->lockName = 'fora_migrations_' . substr(hash('sha256', (string) $database), 0, 40);
    }

    public function deploy(): void
    {
        $this->locked(function (): void {
            $history = $this->history();
            $this->validate($history);
            if ($history === [] && $this->hasApplicationTables()) {
                throw new RuntimeException('Existing database has no migration history. Record its verified starting point using the baseline action before deploying.');
            }
            foreach ($this->files as $name => $path) {
                if (isset($history[$name])) {
                    continue;
                }
                $sql = $this->read($path);
                $insert = $this->pdo->prepare('INSERT INTO schema_migrations (migration_name, checksum, status) VALUES (?, ?, \'running\')');
                $insert->execute([$name, hash('sha256', $sql)]);
                try {
                    $this->pdo->exec($sql);
                    $update = $this->pdo->prepare('UPDATE schema_migrations SET status=\'applied\', finished_at=CURRENT_TIMESTAMP WHERE migration_name=?');
                    $update->execute([$name]);
                } catch (Throwable $error) {
                    $update = $this->pdo->prepare('UPDATE schema_migrations SET status=\'failed\', error_message=? WHERE migration_name=?');
                    $update->execute([$error->getMessage(), $name]);
                    throw new RuntimeException("Migration {$name} failed. Inspect schema_migrations and repair the partial changes before resolving it.", 0, $error);
                }
            }
        });
    }

    public function status(): array
    {
        return $this->locked(function (): array {
            $history = $this->history();
            $rows = [];
            foreach ($this->files as $name => $path) {
                $row = $history[$name] ?? ['status' => 'pending', 'finished_at' => null];
                $row['migration_name'] = $name;
                if (isset($row['checksum']) && $row['checksum'] !== hash('sha256', $this->read($path))) {
                    $row['status'] = 'checksum mismatch';
                }
                $rows[] = $row;
                unset($history[$name]);
            }
            foreach ($history as $row) {
                $row['status'] = 'missing file';
                $rows[] = $row;
            }
            return $rows;
        });
    }

    // Record manually applied history without executing its SQL.
    public function baseline(string $through): void
    {
        if (!isset($this->files[$through])) {
            throw new InvalidArgumentException('Baseline must name an existing migration file.');
        }
        $this->locked(function () use ($through): void {
            if ($this->history() !== [] || !$this->hasApplicationTables()) {
                throw new RuntimeException('Baseline requires an existing database with no migration history.');
            }
            $this->pdo->beginTransaction();
            try {
                $insert = $this->pdo->prepare('INSERT INTO schema_migrations (migration_name, checksum, status, finished_at) VALUES (?, ?, \'baselined\', CURRENT_TIMESTAMP)');
                foreach ($this->files as $name => $path) {
                    $insert->execute([$name, hash('sha256', $this->read($path))]);
                    if ($name === $through) {
                        break;
                    }
                }
                $this->pdo->commit();
            } catch (Throwable $error) {
                $this->pdo->rollBack();
                throw $error;
            }
        });
    }

    public function resolve(string $name, string $resolution): void
    {
        if (!isset($this->files[$name]) || !in_array($resolution, ['applied', 'rolled-back'], true)) {
            throw new InvalidArgumentException('Resolve needs an existing filename and applied or rolled-back.');
        }
        $this->locked(function () use ($name, $resolution): void {
            $history = $this->history();
            $row = $history[$name] ?? null;
            if (!$row || !in_array($row['status'], ['failed', 'running'], true)) {
                throw new RuntimeException('Only a failed or interrupted migration can be resolved.');
            }
            if ($row['checksum'] !== hash('sha256', $this->read($this->files[$name]))) {
                throw new RuntimeException('Restore the original migration file before resolving it.');
            }
            if ($resolution === 'applied') {
                $statement = $this->pdo->prepare('UPDATE schema_migrations SET status=\'applied\', finished_at=CURRENT_TIMESTAMP WHERE migration_name=?');
            } else {
                $statement = $this->pdo->prepare('DELETE FROM schema_migrations WHERE migration_name=?');
            }
            $statement->execute([$name]);
        });
    }

    private function validate(array $history): void
    {
        foreach ($history as $name => $row) {
            if (!isset($this->files[$name])) {
                throw new RuntimeException("Previously recorded migration {$name} is missing.");
            }
            if ($row['checksum'] !== hash('sha256', $this->read($this->files[$name]))) {
                throw new RuntimeException("Previously recorded migration {$name} was modified. Restore the original file and add a new migration.");
            }
            if (!in_array($row['status'], ['applied', 'baselined'], true)) {
                throw new RuntimeException("Migration {$name} is {$row['status']}. Repair its partial changes and use the resolve action.");
            }
        }
        // Prevent a backdated file from running after migrations that depend on its position.
        if (array_keys($history) !== array_slice(array_keys($this->files), 0, count($history))) {
            throw new RuntimeException('Migration order changed. Give new migrations a later filename and preserve the historical order.');
        }
    }

    private function hasApplicationTables(): bool
    {
        return (int) $this->pdo->query("SELECT COUNT(*) FROM information_schema.tables WHERE table_schema=DATABASE() AND table_name <> 'schema_migrations'")->fetchColumn() > 0;
    }

    private function history(): array
    {
        $rows = $this->pdo->query('SELECT * FROM schema_migrations ORDER BY id')->fetchAll(PDO::FETCH_ASSOC);
        return array_column($rows, null, 'migration_name');
    }

    private function read(string $path): string
    {
        $sql = file_get_contents($path);
        if ($sql === false || trim($sql) === '') {
            throw new RuntimeException("Cannot read migration {$path}, or it is empty.");
        }
        return $sql;
    }

    private function locked(callable $operation): mixed
    {
        $lock = $this->pdo->prepare('SELECT GET_LOCK(?, 60)');
        $lock->execute([$this->lockName]);
        if ((int) $lock->fetchColumn() !== 1) {
            throw new RuntimeException('Timed out waiting for the database migration lock.');
        }
        try {
            $this->pdo->exec("CREATE TABLE IF NOT EXISTS schema_migrations (
                id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
                migration_name VARCHAR(191) CHARACTER SET ascii COLLATE ascii_bin NOT NULL UNIQUE,
                checksum CHAR(64) CHARACTER SET ascii NOT NULL,
                status ENUM('running','applied','failed','baselined') NOT NULL,
                started_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                finished_at TIMESTAMP NULL DEFAULT NULL,
                error_message TEXT NULL
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");
            return $operation();
        } finally {
            $release = $this->pdo->prepare('SELECT RELEASE_LOCK(?)');
            $release->execute([$this->lockName]);
        }
    }
}
