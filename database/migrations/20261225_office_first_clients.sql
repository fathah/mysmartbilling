INSERT IGNORE INTO business_sections(section_key,section_name,sort_order) VALUES('office','Office',11);
CREATE TABLE IF NOT EXISTS office_clients (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  company_id BIGINT UNSIGNED NOT NULL,
  company_name VARCHAR(180) NOT NULL,
  owner_rep_name VARCHAR(180) NULL,
  mobile VARCHAR(60) NULL,
  labour_no VARCHAR(100) NULL,
  immigration_no VARCHAR(100) NULL,
  uae_pass_no VARCHAR(100) NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_office_clients_company_name(company_id,company_name),
  INDEX idx_office_clients_company_mobile(company_id,mobile),
  CONSTRAINT fk_office_clients_company FOREIGN KEY(company_id) REFERENCES companies(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
