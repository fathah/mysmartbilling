<?php
if (session_status() !== PHP_SESSION_ACTIVE) {
    session_set_cookie_params(['httponly'=>true, 'secure'=>!empty($_SERVER['HTTPS']), 'samesite'=>'Lax']);
    session_start();
}
function require_login(): void {
    if (empty($_SESSION['user'])) { header('Location: login.php'); exit; }
}
function refresh_user_context(PDO $pdo): ?array {
    $id=(int)($_SESSION['user']['id']??0);
    if(!$id)return null;
    $q=$pdo->prepare('SELECT u.id,u.company_id,u.name,u.photo_path,u.username,u.role,u.active,c.trade_name,c.company_code,c.sales_bill_template,c.sales_bill_color,c.arabic_trade_name,c.address_arabic,c.trn,c.address,c.logo_path,c.subscription_mode,c.subscription_started_at,c.subscription_expires_at,c.demo_expires_at,c.status company_status FROM users u JOIN companies c ON c.id=u.company_id WHERE u.id=?');
    $q->execute([$id]);$user=$q->fetch(PDO::FETCH_ASSOC);
    $demoExpired=$user&&$user['role']!=='super_admin'&&!empty($user['demo_expires_at'])&&(new DateTimeImmutable('today',new DateTimeZone('Asia/Dubai')))>=new DateTimeImmutable($user['demo_expires_at'],new DateTimeZone('Asia/Dubai'));
    if(!$user||!(int)$user['active']||$demoExpired||($user['company_status']!=='approved'&&$user['role']!=='super_admin')){$_SESSION=[];session_destroy();return null;}
    $q=$pdo->prepare('SELECT section_key FROM company_sections WHERE company_id=? AND enabled=1');$q->execute([$user['company_id']]);
    $user['sections']=array_column($q->fetchAll(PDO::FETCH_ASSOC),'section_key');
    if($user['role']==='super_admin')$user['sections']=array_column($pdo->query('SELECT section_key FROM business_sections ORDER BY sort_order')->fetchAll(PDO::FETCH_ASSOC),'section_key');
    unset($user['active'],$user['company_status']);$_SESSION['user']=$user;return $user;
}
function has_section(array $user,string $section): bool {return ($user['role']??'')==='super_admin'||in_array($section,$user['sections']??[],true);}
function require_role(array $user,array $roles): void {if(!in_array($user['role']??'', $roles,true)){http_response_code(403);exit('Access denied.');}}
function csrf_token(): string {
    if (empty($_SESSION['csrf'])) $_SESSION['csrf'] = bin2hex(random_bytes(32));
    return $_SESSION['csrf'];
}
function verify_csrf(): void {
    $provided = $_POST['csrf'] ?? ($_SERVER['HTTP_X_CSRF'] ?? '');
    if (!hash_equals($_SESSION['csrf'] ?? '', $provided)) { http_response_code(419); exit('Session expired. Refresh and try again.'); }
}
