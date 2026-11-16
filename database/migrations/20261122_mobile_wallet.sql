ALTER TABLE mobile_sales
  ADD COLUMN customer_id BIGINT UNSIGNED NULL AFTER payment_reference,
  ADD INDEX idx_mobile_sales_customer(company_id,customer_id),
  ADD CONSTRAINT fk_mobile_sales_customer FOREIGN KEY(customer_id) REFERENCES mobile_clients(id) ON DELETE SET NULL;

CREATE TABLE IF NOT EXISTS mobile_wallet_withdrawals (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  company_id BIGINT UNSIGNED NOT NULL,
  withdrawal_date DATE NOT NULL,
  name VARCHAR(160) NOT NULL,
  notes VARCHAR(500) NULL,
  amount DECIMAL(12,2) NOT NULL,
  created_by BIGINT UNSIGNED NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_mobile_wallet_company_date(company_id,withdrawal_date),
  CONSTRAINT fk_mobile_wallet_company FOREIGN KEY(company_id) REFERENCES companies(id) ON DELETE CASCADE,
  CONSTRAINT fk_mobile_wallet_user FOREIGN KEY(created_by) REFERENCES users(id)
);
