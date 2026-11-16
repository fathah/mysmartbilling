CREATE TABLE IF NOT EXISTS mobile_purchases (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  company_id BIGINT UNSIGNED NOT NULL,
  supplier_id BIGINT UNSIGNED NOT NULL,
  invoice_number VARCHAR(120) NOT NULL,
  purchase_date DATE NOT NULL,
  supplier_trn VARCHAR(80) NULL,
  supplier_contact VARCHAR(60) NOT NULL,
  total_amount DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  paid_amount DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  balance_amount DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_mobile_purchase_invoice(company_id,invoice_number),
  INDEX idx_mobile_purchase_company_date(company_id,purchase_date),
  CONSTRAINT fk_mobile_purchases_company FOREIGN KEY(company_id) REFERENCES companies(id) ON DELETE CASCADE,
  CONSTRAINT fk_mobile_purchases_supplier FOREIGN KEY(supplier_id) REFERENCES mobile_suppliers(id)
);

CREATE TABLE IF NOT EXISTS mobile_purchase_lines (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  purchase_id BIGINT UNSIGNED NOT NULL,
  company_id BIGINT UNSIGNED NOT NULL,
  item_name VARCHAR(160) NOT NULL,
  model VARCHAR(160) NOT NULL,
  model_year SMALLINT UNSIGNED NOT NULL,
  unit_amount DECIMAL(12,2) NOT NULL,
  quantity INT UNSIGNED NOT NULL,
  line_total DECIMAL(12,2) NOT NULL,
  INDEX idx_mobile_purchase_lines_company(purchase_id,company_id),
  CONSTRAINT fk_mobile_purchase_lines_purchase FOREIGN KEY(purchase_id) REFERENCES mobile_purchases(id) ON DELETE CASCADE,
  CONSTRAINT fk_mobile_purchase_lines_company FOREIGN KEY(company_id) REFERENCES companies(id) ON DELETE CASCADE
);
