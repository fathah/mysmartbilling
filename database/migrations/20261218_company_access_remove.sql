ALTER TABLE companies
  MODIFY status ENUM('pending','approved','rejected','suspended','removed') NOT NULL DEFAULT 'pending',
  ADD COLUMN removed_previous_status ENUM('pending','approved','rejected','suspended') NULL AFTER status,
  ADD COLUMN removed_at DATETIME NULL AFTER removed_previous_status,
  ADD COLUMN removed_by BIGINT UNSIGNED NULL AFTER removed_at;