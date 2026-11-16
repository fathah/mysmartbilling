CREATE TABLE IF NOT EXISTS mobile_customer_payments (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  company_id BIGINT UNSIGNED NOT NULL,
  sale_id BIGINT UNSIGNED NOT NULL,
  payment_date DATE NOT NULL,
  amount DECIMAL(12,2) NOT NULL,
  payment_method ENUM('Cash','Card','Bank','Tabby','Tamara') NOT NULL,
  received_by BIGINT UNSIGNED NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_customer_payment_company_sale(company_id,sale_id),
  INDEX idx_customer_payment_company_date(company_id,payment_date),
  CONSTRAINT fk_customer_payment_company FOREIGN KEY(company_id) REFERENCES companies(id) ON DELETE CASCADE,
  CONSTRAINT fk_customer_payment_sale FOREIGN KEY(sale_id) REFERENCES mobile_sales(id) ON DELETE RESTRICT,
  CONSTRAINT fk_customer_payment_user FOREIGN KEY(received_by) REFERENCES users(id)
);