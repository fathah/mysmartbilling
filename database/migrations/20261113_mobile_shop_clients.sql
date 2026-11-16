CREATE TABLE IF NOT EXISTS mobile_clients (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  company_id BIGINT UNSIGNED NOT NULL,
  name VARCHAR(160) NOT NULL,
  trn VARCHAR(80) NULL,
  emirate VARCHAR(80) NOT NULL,
  mobile VARCHAR(60) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_mobile_clients_company_name(company_id,name),
  INDEX idx_mobile_clients_company_mobile(company_id,mobile),
  CONSTRAINT fk_mobile_clients_company FOREIGN KEY(company_id) REFERENCES companies(id) ON DELETE CASCADE
);
