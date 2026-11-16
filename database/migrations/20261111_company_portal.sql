CREATE TABLE IF NOT EXISTS companies (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  company_code VARCHAR(24) NOT NULL UNIQUE,
  trade_name VARCHAR(180) NOT NULL,
  business_field VARCHAR(40) NOT NULL,
  email VARCHAR(190) NOT NULL UNIQUE,
  contact_number VARCHAR(60) NOT NULL,
  subscription_mode ENUM('monthly','yearly') NOT NULL,
  status ENUM('pending','approved','rejected','suspended') NOT NULL DEFAULT 'pending',
  requested_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  reviewed_at TIMESTAMP NULL,
  reviewed_by BIGINT UNSIGNED NULL
);

CREATE TABLE IF NOT EXISTS business_sections (
  section_key VARCHAR(40) PRIMARY KEY,
  section_name VARCHAR(100) NOT NULL,
  sort_order TINYINT UNSIGNED NOT NULL
);
INSERT IGNORE INTO business_sections(section_key,section_name,sort_order) VALUES
('real_estate','Real Estate',1),('mobile_shop','Mobile Shop',2),('grocery','Grocery',3),
('supermarket','Supermarket',4),('car_rental','Car Rental',5),('restaurant','Restaurant',6),
('pharmacy','Pharmacy',7),('electronics','Electronics',8),('fashion','Fashion',9),('other','Other',10);

CREATE TABLE IF NOT EXISTS company_sections (
  company_id BIGINT UNSIGNED NOT NULL,
  section_key VARCHAR(40) NOT NULL,
  enabled TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY(company_id,section_key),
  CONSTRAINT fk_company_sections_company FOREIGN KEY(company_id) REFERENCES companies(id) ON DELETE CASCADE,
  CONSTRAINT fk_company_sections_section FOREIGN KEY(section_key) REFERENCES business_sections(section_key)
);

ALTER TABLE users ADD COLUMN company_id BIGINT UNSIGNED NULL AFTER id;
ALTER TABLE users MODIFY role ENUM('super_admin','admin','user','staff') NOT NULL DEFAULT 'staff';
UPDATE users SET role=IF(role='staff','user','admin');
ALTER TABLE users MODIFY role ENUM('super_admin','admin','user') NOT NULL DEFAULT 'user';

INSERT IGNORE INTO companies(company_code,trade_name,business_field,email,contact_number,subscription_mode,status)
VALUES('FORA-DEFAULT','Fora Real Estate','real_estate','fora-office@example.invalid','N/A','yearly','approved');
SET @default_company_id=(SELECT id FROM companies WHERE company_code='FORA-DEFAULT' LIMIT 1);
UPDATE users SET company_id=@default_company_id WHERE company_id IS NULL;
UPDATE users SET role='super_admin' WHERE username='asharafsaadi1@gmail.com';
ALTER TABLE users MODIFY company_id BIGINT UNSIGNED NOT NULL;
ALTER TABLE users ADD INDEX idx_users_company(company_id),
  ADD CONSTRAINT fk_users_company FOREIGN KEY(company_id) REFERENCES companies(id);

ALTER TABLE properties ADD COLUMN company_id BIGINT UNSIGNED NULL AFTER id;
ALTER TABLE units ADD COLUMN company_id BIGINT UNSIGNED NULL AFTER id;
ALTER TABLE tenants ADD COLUMN company_id BIGINT UNSIGNED NULL AFTER id;
ALTER TABLE tenancies ADD COLUMN company_id BIGINT UNSIGNED NULL AFTER id;
ALTER TABLE cheques ADD COLUMN company_id BIGINT UNSIGNED NULL AFTER id;
ALTER TABLE contract_dues ADD COLUMN company_id BIGINT UNSIGNED NULL AFTER id;
ALTER TABLE bills ADD COLUMN company_id BIGINT UNSIGNED NULL AFTER id;
ALTER TABLE tenancy_renewals ADD COLUMN company_id BIGINT UNSIGNED NULL AFTER id;

UPDATE properties SET company_id=@default_company_id WHERE company_id IS NULL;
UPDATE units u JOIN properties p ON p.id=u.property_id SET u.company_id=p.company_id WHERE u.company_id IS NULL;
UPDATE tenants SET company_id=@default_company_id WHERE company_id IS NULL;
UPDATE tenancies t JOIN units u ON u.id=t.unit_id SET t.company_id=u.company_id WHERE t.company_id IS NULL;
UPDATE cheques c JOIN tenancies t ON t.id=c.tenancy_id SET c.company_id=t.company_id WHERE c.company_id IS NULL;
UPDATE contract_dues d JOIN tenancies t ON t.id=d.tenancy_id SET d.company_id=t.company_id WHERE d.company_id IS NULL;
UPDATE bills SET company_id=@default_company_id WHERE company_id IS NULL;
UPDATE tenancy_renewals r JOIN tenancies t ON t.id=r.tenancy_id SET r.company_id=t.company_id WHERE r.company_id IS NULL;

ALTER TABLE properties MODIFY company_id BIGINT UNSIGNED NOT NULL, ADD INDEX idx_properties_company(company_id), ADD CONSTRAINT fk_properties_company FOREIGN KEY(company_id) REFERENCES companies(id);
ALTER TABLE units MODIFY company_id BIGINT UNSIGNED NOT NULL, ADD INDEX idx_units_company(company_id), ADD CONSTRAINT fk_units_company FOREIGN KEY(company_id) REFERENCES companies(id);
ALTER TABLE tenants MODIFY company_id BIGINT UNSIGNED NOT NULL, ADD INDEX idx_tenants_company(company_id), ADD CONSTRAINT fk_tenants_company FOREIGN KEY(company_id) REFERENCES companies(id);
ALTER TABLE tenancies MODIFY company_id BIGINT UNSIGNED NOT NULL, ADD INDEX idx_tenancies_company(company_id), ADD CONSTRAINT fk_tenancies_company FOREIGN KEY(company_id) REFERENCES companies(id);
ALTER TABLE cheques MODIFY company_id BIGINT UNSIGNED NOT NULL, DROP INDEX uq_cheque_bank_number, ADD UNIQUE KEY uq_company_cheque_bank_number(company_id,bank_name,cheque_number), ADD CONSTRAINT fk_cheques_company FOREIGN KEY(company_id) REFERENCES companies(id);
ALTER TABLE contract_dues MODIFY company_id BIGINT UNSIGNED NOT NULL, ADD INDEX idx_dues_company(company_id), ADD CONSTRAINT fk_dues_company FOREIGN KEY(company_id) REFERENCES companies(id);
ALTER TABLE bills MODIFY company_id BIGINT UNSIGNED NOT NULL, ADD INDEX idx_bills_company(company_id), ADD CONSTRAINT fk_bills_company FOREIGN KEY(company_id) REFERENCES companies(id);
ALTER TABLE tenancy_renewals MODIFY company_id BIGINT UNSIGNED NOT NULL, ADD INDEX idx_renewals_company(company_id), ADD CONSTRAINT fk_renewals_company FOREIGN KEY(company_id) REFERENCES companies(id);

INSERT IGNORE INTO company_sections(company_id,section_key,enabled)
SELECT @default_company_id,section_key,1 FROM business_sections;
