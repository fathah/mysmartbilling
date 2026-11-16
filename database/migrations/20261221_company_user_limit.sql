ALTER TABLE companies
  ADD COLUMN user_limit SMALLINT UNSIGNED NOT NULL DEFAULT 5 AFTER demo_expires_at;
UPDATE companies c
SET c.user_limit=GREATEST(c.user_limit,(SELECT COUNT(*) FROM users u WHERE u.company_id=c.id AND u.role<>'super_admin'));