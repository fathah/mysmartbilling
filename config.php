<?php
// Copy config.example.php to config.local.php for machine-specific credentials.
$localConfig = __DIR__ . '/config.local.php';
return require (is_file($localConfig) ? $localConfig : __DIR__ . '/config.example.php');
