ALTER TABLE mobile_suppliers
  ADD COLUMN salesman_name VARCHAR(160) NULL AFTER contact_person,
  ADD COLUMN salesman_mobile VARCHAR(60) NULL AFTER salesman_name;

ALTER TABLE mobile_purchases
  ADD COLUMN supplier_bill_number VARCHAR(100) NULL AFTER invoice_number,
  ADD COLUMN supplier_bill_date DATE NULL AFTER purchase_date,
  ADD COLUMN payment_due_date DATE NULL AFTER supplier_bill_date;

CREATE TABLE IF NOT EXISTS mobile_supplier_payments (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  company_id BIGINT UNSIGNED NOT NULL,
  supplier_id BIGINT UNSIGNED NOT NULL,
  purchase_id BIGINT UNSIGNED NOT NULL,
  payment_date DATE NOT NULL,
  amount DECIMAL(12,2) NOT NULL,
  payment_method ENUM('Cash','Card','Bank','Transfer') NOT NULL DEFAULT 'Cash',
  reference VARCHAR(160) NULL,
  notes TEXT NULL,
  created_by BIGINT UNSIGNED NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_supplier_payments_company_date(company_id,payment_date),
  INDEX idx_supplier_payments_supplier_date(supplier_id,payment_date),
  INDEX idx_supplier_payments_purchase(purchase_id),
  CONSTRAINT fk_supplier_payments_company FOREIGN KEY(company_id) REFERENCES companies(id) ON DELETE CASCADE,
  CONSTRAINT fk_supplier_payments_supplier FOREIGN KEY(supplier_id) REFERENCES mobile_suppliers(id) ON DELETE CASCADE,
  CONSTRAINT fk_supplier_payments_purchase FOREIGN KEY(purchase_id) REFERENCES mobile_purchases(id) ON DELETE CASCADE,
  CONSTRAINT fk_supplier_payments_user FOREIGN KEY(created_by) REFERENCES users(id) ON DELETE SET NULL
);