CREATE TABLE IF NOT EXISTS mobile_sale_returns (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  company_id BIGINT UNSIGNED NOT NULL,
  sale_id BIGINT UNSIGNED NOT NULL,
  return_date DATE NOT NULL,
  return_quantity INT UNSIGNED NOT NULL,
  return_amount DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  notes VARCHAR(500) NULL,
  created_by BIGINT UNSIGNED NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_mobile_sale_return_company_date(company_id,return_date),
  INDEX idx_mobile_sale_return_sale(company_id,sale_id),
  CONSTRAINT fk_mobile_sale_return_company FOREIGN KEY(company_id) REFERENCES companies(id) ON DELETE CASCADE,
  CONSTRAINT fk_mobile_sale_return_sale FOREIGN KEY(sale_id) REFERENCES mobile_sales(id) ON DELETE RESTRICT,
  CONSTRAINT fk_mobile_sale_return_user FOREIGN KEY(created_by) REFERENCES users(id)
);