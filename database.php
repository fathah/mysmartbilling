<?php
function db(): PDO {
    static $pdo;
    if ($pdo instanceof PDO) return $pdo;
    $cfg = require __DIR__ . '/config.php';
    $connection = new PDO("mysql:host={$cfg['host']};dbname={$cfg['database']};charset={$cfg['charset']}", $cfg['username'], $cfg['password'], [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        PDO::ATTR_EMULATE_PREPARES => false,
    ]);
    $pdo = $connection;
    return $pdo;
}
