CREATE TABLE IF NOT EXISTS mobile_wallet_opening_balances (
  company_id BIGINT UNSIGNED PRIMARY KEY,
  effective_date DATE NOT NULL,
  cash_amount DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  bank_amount DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  notes VARCHAR(500) NULL,
  updated_by BIGINT UNSIGNED NOT NULL,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_mobile_wallet_opening_company FOREIGN KEY(company_id) REFERENCES companies(id) ON DELETE CASCADE,
  CONSTRAINT fk_mobile_wallet_opening_user FOREIGN KEY(updated_by) REFERENCES users(id)
);
