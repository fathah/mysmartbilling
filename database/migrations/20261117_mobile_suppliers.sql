CREATE TABLE IF NOT EXISTS mobile_suppliers (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  company_id BIGINT UNSIGNED NOT NULL,
  supplier_name VARCHAR(180) NOT NULL,
  contact_person VARCHAR(160) NULL,
  trn VARCHAR(80) NULL,
  emirate VARCHAR(80) NULL,
  mobile VARCHAR(60) NOT NULL,
  email VARCHAR(190) NULL,
  address TEXT NULL,
  notes TEXT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_mobile_suppliers_company_name(company_id,supplier_name),
  INDEX idx_mobile_suppliers_company_mobile(company_id,mobile),
  CONSTRAINT fk_mobile_suppliers_company FOREIGN KEY(company_id) REFERENCES companies(id) ON DELETE CASCADE
);
