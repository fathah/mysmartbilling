CREATE TABLE IF NOT EXISTS mobile_wallet_transfers (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  company_id BIGINT UNSIGNED NOT NULL,
  transfer_date DATE NOT NULL,
  bank_account VARCHAR(160) NOT NULL,
  amount DECIMAL(12,2) NOT NULL,
  reference VARCHAR(160) NULL,
  notes VARCHAR(500) NULL,
  created_by BIGINT UNSIGNED NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_wallet_transfer_company_date(company_id,transfer_date),
  CONSTRAINT fk_wallet_transfer_company FOREIGN KEY(company_id) REFERENCES companies(id) ON DELETE CASCADE,
  CONSTRAINT fk_wallet_transfer_user FOREIGN KEY(created_by) REFERENCES users(id)
);