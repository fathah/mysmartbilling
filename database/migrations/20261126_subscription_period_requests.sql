ALTER TABLE companies
  ADD COLUMN subscription_started_at DATE NULL AFTER subscription_mode,
  ADD COLUMN subscription_expires_at DATE NULL AFTER subscription_started_at;

ALTER TABLE users
  ADD COLUMN photo_path VARCHAR(255) NULL AFTER name;

UPDATE companies
SET subscription_started_at=COALESCE(DATE(reviewed_at),DATE(requested_at)),
    subscription_expires_at=CASE
      WHEN subscription_mode='yearly' THEN DATE_ADD(COALESCE(DATE(reviewed_at),DATE(requested_at)),INTERVAL 1 YEAR)
      ELSE DATE_ADD(COALESCE(DATE(reviewed_at),DATE(requested_at)),INTERVAL 1 MONTH)
    END
WHERE status='approved' AND subscription_expires_at IS NULL;

CREATE TABLE IF NOT EXISTS subscription_requests (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  request_number VARCHAR(32) NOT NULL UNIQUE,
  company_id BIGINT UNSIGNED NOT NULL,
  requested_mode ENUM('monthly','yearly') NOT NULL,
  status ENUM('pending_review','awaiting_payment','paid','rejected') NOT NULL DEFAULT 'pending_review',
  requested_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  reviewed_at TIMESTAMP NULL,
  reviewed_by BIGINT UNSIGNED NULL,
  paid_at TIMESTAMP NULL,
  paid_amount DECIMAL(12,2) NULL,
  bill_number VARCHAR(100) NULL,
  bank_transfer_details VARCHAR(500) NULL,
  subscription_starts_at DATE NULL,
  subscription_expires_at DATE NULL,
  CONSTRAINT fk_subscription_request_company FOREIGN KEY(company_id) REFERENCES companies(id) ON DELETE CASCADE,
  INDEX idx_subscription_request_status(status,requested_at),
  INDEX idx_subscription_request_company(company_id,requested_at)
);
