<?php
// Exercises the HTTP entry point against a disposable database and local server.
if (PHP_SAPI !== 'cli') {
    http_response_code(404);
    exit;
}

function endpoint_check(bool $condition, string $message): void
{
    if (!$condition) {
        throw new RuntimeException($message);
    }
}

function endpoint_request(string $url, ?array $body = null, bool $json = true): array
{
    $curl = curl_init($url);
    $headers = $json ? ['Accept: application/json'] : [];
    curl_setopt_array($curl, [CURLOPT_RETURNTRANSFER => true, CURLOPT_TIMEOUT => 30, CURLOPT_HTTPHEADER => $headers]);
    if ($body !== null) {
        curl_setopt($curl, CURLOPT_POSTFIELDS, http_build_query($body));
    }
    $response = curl_exec($curl);
    $status = curl_getinfo($curl, CURLINFO_RESPONSE_CODE);
    $error = curl_error($curl);
    curl_close($curl);
    endpoint_check($response !== false, 'HTTP request failed. ' . $error);
    return [$status, $json ? json_decode($response, true, 512, JSON_THROW_ON_ERROR) : $response];
}

$cfg = require __DIR__ . '/../config.php';
$options = [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION];
$server = new PDO("mysql:host={$cfg['host']};charset={$cfg['charset']}", $cfg['username'], $cfg['password'], $options);
$name = 'fora_endpoint_test_' . bin2hex(random_bytes(6));
$directory = sys_get_temp_dir() . '/' . $name;
mkdir($directory);
$server->exec("CREATE DATABASE `{$name}` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci");
$process = null;
try {
    $cfg['database'] = $name;
    $cfg['migration_password'] = '';
    $configFile = $directory . '/config.local.php';
    file_put_contents($configFile, '<?php return ' . var_export($cfg, true) . ';');
    foreach (['migrate.php', 'database.php', 'config.php', 'config.example.php'] as $file) {
        copy(__DIR__ . '/../' . $file, $directory . '/' . $file);
    }
    symlink(realpath(__DIR__ . '/../database'), $directory . '/database');
    $socket = stream_socket_server('tcp://127.0.0.1:0', $errorNumber, $errorMessage);
    endpoint_check($socket !== false, 'Cannot allocate a local test port.');
    $address = stream_socket_get_name($socket, false);
    fclose($socket);
    $pipes = [];
    $log = $directory . '/server.log';
    $process = proc_open([PHP_BINARY, '-S', $address, '-t', $directory], [1 => ['file', $log, 'a'], 2 => ['file', $log, 'a']], $pipes);
    endpoint_check(is_resource($process), 'Cannot start HTTP server.');
    $ready = false;
    for ($attempt = 0; $attempt < 30; $attempt++) {
        $probe = @stream_socket_client('tcp://' . $address, $errorNumber, $errorMessage, 0.1);
        if ($probe) {
            fclose($probe);
            $ready = true;
            break;
        }
        usleep(100000);
    }
    endpoint_check($ready, 'HTTP server did not start.');
    $url = 'http://' . $address . '/migrate.php';
    [$status, $html] = endpoint_request($url, null, false);
    endpoint_check($status === 200 && str_contains($html, 'Migration password'), 'Browser form failed.');
    [$status, $body] = endpoint_request($url, ['password' => 'anything', 'action' => 'deploy']);
    endpoint_check($status === 503 && !$body['ok'], 'Empty configured password did not disable endpoint.');
    $cfg['migration_password'] = bin2hex(random_bytes(24));
    file_put_contents($configFile, '<?php return ' . var_export($cfg, true) . ';');
    [$status, $body] = endpoint_request($url . '?password=' . $cfg['migration_password'], null);
    endpoint_check($status === 200 && $body['migrations'] === [], 'GET exposed migration history.');
    [$status, $body] = endpoint_request($url, ['password' => 'wrong', 'action' => 'deploy']);
    endpoint_check($status === 401 && $body['migrations'] === [], 'Wrong password accepted or exposed history.');
    [$status, $body] = endpoint_request($url, ['password' => ['invalid'], 'action' => 'deploy']);
    endpoint_check($status === 401, 'Array password was accepted.');
    $pdo = new PDO("mysql:host={$cfg['host']};dbname={$name};charset={$cfg['charset']}", $cfg['username'], $cfg['password'], $options);
    endpoint_check((int) $pdo->query('SELECT COUNT(*) FROM information_schema.tables WHERE table_schema=DATABASE()')->fetchColumn() === 0, 'Unauthenticated request touched database.');
    // Ordinary application database access should leave pending migrations for the protected endpoint.
    file_put_contents($directory . '/connection.php', '<?php require __DIR__ . "/database.php"; db(); echo "connected";');
    [$status, $html] = endpoint_request('http://' . $address . '/connection.php', null, false);
    endpoint_check($status === 200 && $html === 'connected', 'Normal connection failed.');
    endpoint_check((int) $pdo->query('SELECT COUNT(*) FROM information_schema.tables WHERE table_schema=DATABASE()')->fetchColumn() === 0, 'Ordinary database connection applied migrations.');
    echo "PASS browser form, disabled endpoint, password rejection, GET privacy, normal connections\n";

    $auth = ['password' => $cfg['migration_password']];
    [$status, $body] = endpoint_request($url, $auth + ['action' => 'invalid']);
    endpoint_check($status === 400, 'Unknown action accepted.');
    [$status, $body] = endpoint_request($url, $auth + ['action' => 'baseline', 'migration' => '../config.php']);
    endpoint_check($status === 400, 'Invalid baseline filename accepted.');
    [$status, $body] = endpoint_request($url, $auth + ['action' => 'status']);
    endpoint_check($status === 200 && $body['ok'] && $body['last_completed_migration'] === null, 'Authenticated status failed.');
    endpoint_check(count($body['migrations']) === count(glob(__DIR__ . '/../database/migrations/*.sql')), 'Pending migration list incomplete.');
    [$status, $body] = endpoint_request($url, $auth + ['action' => 'deploy']);
    endpoint_check($status === 200 && $body['ok'] && $body['last_completed_migration'] === '20261230_office_client_wallet_entries.sql', 'Authenticated deployment failed.');
    [$status, $body] = endpoint_request($url, $auth + ['action' => 'deploy']);
    endpoint_check($status === 200 && $body['ok'], 'Repeated HTTP deploy failed.');
    [$status, $html] = endpoint_request($url, $auth + ['action' => 'status'], false);
    endpoint_check($status === 200 && str_contains($html, '20261230_office_client_wallet_entries.sql'), 'HTML results missing.');
    endpoint_check(!str_contains($html, $cfg['migration_password']), 'HTML echoed the password.');
    echo "PASS authenticated status, input validation, deployment, repeat deploy, HTML results\n";

    $pdo->exec("UPDATE schema_migrations SET status='failed', error_message='test failure' WHERE migration_name='20261230_office_client_wallet_entries.sql'");
    [$status, $body] = endpoint_request($url, $auth + ['action' => 'deploy']);
    endpoint_check($status === 500 && !$body['ok'], 'Failed migration returned success.');
    [$status, $body] = endpoint_request($url, $auth + ['action' => 'resolve', 'migration' => '20261230_office_client_wallet_entries.sql', 'resolution' => 'applied']);
    endpoint_check($status === 200 && $body['ok'], 'HTTP resolution failed.');
    $pdo->exec('DROP TABLE schema_migrations');
    [$status, $body] = endpoint_request($url, $auth + ['action' => 'baseline', 'migration' => '20261230_office_client_wallet_entries.sql']);
    endpoint_check($status === 200 && $body['ok'] && $body['migrations'][0]['status'] === 'baselined', 'HTTP baseline failed.');
    echo "PASS failure response, resolution, existing database baseline\n";
} finally {
    if (is_resource($process)) {
        proc_terminate($process);
        proc_close($process);
    }
    $server->exec("DROP DATABASE `{$name}`");
    if (is_link($directory . '/database')) {
        unlink($directory . '/database');
    }
    foreach (glob($directory . '/*') as $file) {
        unlink($file);
    }
    rmdir($directory);
}
