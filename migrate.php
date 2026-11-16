<?php

header('Cache-Control: no-store');
header('X-Robots-Tag: noindex, nofollow');
header('X-Frame-Options: DENY');
header('Referrer-Policy: no-referrer');
header("Content-Security-Policy: default-src 'none'; style-src 'unsafe-inline'; form-action 'self'; frame-ancestors 'none'");

$rows = [];
$message = '';
$error = '';
$lastMigration = null;
$method = $_SERVER['REQUEST_METHOD'] ?? 'GET';
$json = str_contains($_SERVER['HTTP_ACCEPT'] ?? '', 'application/json');

if (!in_array($method, ['GET', 'POST'], true)) {
    header('Allow: GET, POST');
    http_response_code(405);
    $error = 'Use GET to open the form or POST to run a migration action.';
} elseif ($method === 'POST') {
    $cfg = require __DIR__ . '/config.php';
    $expectedPassword = $cfg['migration_password'] ?? '';
    $password = $_POST['password'] ?? '';
    if (!is_string($expectedPassword) || $expectedPassword === '') {
        http_response_code(503);
        $error = 'Set migration_password in config.local.php to enable this endpoint.';
    } elseif (!is_string($password) || !hash_equals($expectedPassword, $password)) {
        http_response_code(401);
        $error = 'Invalid migration password.';
    } else {
        $action = $_POST['action'] ?? 'status';
        $migration = $_POST['migration'] ?? '';
        $resolution = $_POST['resolution'] ?? '';
        if (!is_string($action) || !in_array($action, ['status', 'deploy', 'baseline', 'resolve'], true)
            || !is_string($migration) || !is_string($resolution)) {
            http_response_code(400);
            $error = 'Choose status, deploy, baseline, or resolve with valid form fields.';
        } else {
            try {
                require_once __DIR__ . '/database.php';
                require_once __DIR__ . '/database/Migrator.php';
                $migrator = new Migrator(db());
                switch ($action) {
                    case 'deploy':
                        $migrator->deploy();
                        $message = 'Database migrations are up to date.';
                        break;
                    case 'baseline':
                        $migrator->baseline(trim($migration));
                        $message = 'Existing migration history recorded.';
                        break;
                    case 'resolve':
                        $migrator->resolve(trim($migration), $resolution);
                        $message = 'Migration resolution recorded.';
                        break;
                    case 'status':
                        $message = 'Migration status loaded.';
                        break;
                }
                $rows = $migrator->status();
                foreach ($rows as $row) {
                    if (in_array($row['status'], ['applied', 'baselined'], true)) {
                        $lastMigration = $row['migration_name'];
                    }
                }
            } catch (InvalidArgumentException $exception) {
                http_response_code(400);
                $error = $exception->getMessage();
            } catch (Throwable $exception) {
                http_response_code(500);
                $error = $exception->getMessage();
                if ($exception->getPrevious()) {
                    $error .= ' ' . $exception->getPrevious()->getMessage();
                }
            }
        }
    }
}

if ($json) {
    header('Content-Type: application/json; charset=utf-8');
    echo json_encode([
        'ok' => $error === '',
        'message' => $message,
        'error' => $error === '' ? null : $error,
        'last_completed_migration' => $lastMigration,
        'migrations' => $rows,
    ], JSON_INVALID_UTF8_SUBSTITUTE);
    exit;
}

header('Content-Type: text/html; charset=utf-8');
function migration_escape(string $value): string
{
    return htmlspecialchars($value, ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8');
}
?>
<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Database migrations</title>
    <style>
        * { box-sizing: border-box; }
        body { margin: 0; background: #f5f7f6; color: #172b22; font: 16px/1.5 system-ui, sans-serif; }
        main { max-width: 900px; margin: 40px auto; padding: 24px; }
        h1 { margin-top: 0; font-size: 28px; }
        form, .results { padding: 24px; background: white; border: 1px solid #dce4df; border-radius: 12px; margin: 20px 0; }
        label { display: block; margin: 16px 0 6px; font-weight: 600; }
        input, select, button { width: 100%; padding: 12px; font: inherit; border: 1px solid #a4b5ab; border-radius: 6px; }
        button { margin-top: 24px; background: #193b2e; color: white; cursor: pointer; }
        .error { padding: 16px; background: #fff0ee; color: #8d261d; border-radius: 6px; overflow-wrap: anywhere; }
        .success { padding: 16px; background: #e6f3eb; border-radius: 6px; }
        .table-scroll { overflow-x: auto; }
        table { width: 100%; border-collapse: collapse; text-align: left; font-size: 14px; }
        th, td { padding: 12px 8px; border-bottom: 1px solid #dce4df; }
        code { overflow-wrap: anywhere; }
        small { display: block; margin-top: 6px; color: #506359; }
        @media (max-width: 600px) { main { margin: 16px auto; padding: 16px; } form, .results { padding: 16px; } }
    </style>
</head>
<body>
<main>
    <h1>Database migrations</h1>
    <?php if ($error !== ''): ?>
        <p class="error" role="alert"><?= migration_escape($error) ?></p>
    <?php elseif ($message !== ''): ?>
        <p class="success" role="status"><?= migration_escape($message) ?></p>
    <?php endif; ?>
    <form method="post" action="migrate.php">
        <label for="password">Migration password</label>
        <input id="password" name="password" type="password" required autocomplete="off">
        <label for="action">Action</label>
        <select id="action" name="action">
            <option value="status">View migration status</option>
            <option value="deploy">Apply pending migrations</option>
            <option value="baseline">Record existing migration history</option>
            <option value="resolve">Resolve a repaired migration</option>
        </select>
        <label for="migration">Migration filename</label>
        <input id="migration" name="migration" type="text" placeholder="20261230_office_client_wallet_entries.sql">
        <small>Required for baseline and resolve. Baseline records all files through this migration as already applied. Verify the existing database first.</small>
        <label for="resolution">Resolution after manual repair</label>
        <select id="resolution" name="resolution">
            <option value="">Choose when resolving a migration</option>
            <option value="applied">All changes manually completed</option>
            <option value="rolled-back">All partial changes manually undone</option>
        </select>
        <button type="submit">Run selected action</button>
    </form>
    <?php if ($rows !== []): ?>
        <section class="results" aria-label="Migration status">
            <p>Last completed migration <code><?= migration_escape($lastMigration ?? 'none') ?></code></p>
            <div class="table-scroll">
                <table>
                    <thead><tr><th scope="col">Migration</th><th scope="col">Status</th><th scope="col">Completed</th><th scope="col">Error</th></tr></thead>
                    <tbody>
                    <?php foreach ($rows as $row): ?>
                        <tr>
                            <td><?= migration_escape($row['migration_name']) ?></td>
                            <td><?= migration_escape($row['status']) ?></td>
                            <td><?= migration_escape($row['finished_at'] ?? '') ?></td>
                            <td><?= migration_escape($row['error_message'] ?? '') ?></td>
                        </tr>
                    <?php endforeach; ?>
                    </tbody>
                </table>
            </div>
        </section>
    <?php endif; ?>
</main>
</body>
</html>
