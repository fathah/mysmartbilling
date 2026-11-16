-- Run once after the earlier renewal and tenant-code migrations.
ALTER TABLE tenancies
  ADD COLUMN contract_date DATE NULL AFTER previous_tenancy_id,
  ADD COLUMN vat_amount DECIMAL(12,2) NOT NULL DEFAULT 0 AFTER yearly_rent,
  ADD COLUMN total_amount DECIMAL(12,2) NOT NULL DEFAULT 0 AFTER vat_amount,
  ADD COLUMN first_payment_cash DECIMAL(12,2) NOT NULL DEFAULT 0 AFTER total_amount;
UPDATE tenancies SET contract_date=DATE(created_at), vat_amount=ROUND(yearly_rent*0.05,2), total_amount=yearly_rent+ROUND(yearly_rent*0.05,2) WHERE contract_date IS NULL;
ALTER TABLE tenancies MODIFY contract_date DATE NOT NULL;

ALTER TABLE cheques ADD UNIQUE KEY uq_cheque_bank_number (bank_name, cheque_number);

CREATE TABLE contract_dues (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenancy_id BIGINT UNSIGNED NOT NULL,
  category ENUM('Commission','Security') NOT NULL,
  amount DECIMAL(12,2) NOT NULL DEFAULT 0,
  status ENUM('Draft','Pending','Paid') NOT NULL DEFAULT 'Draft',
  paid_at DATE NULL,
  receipt_no VARCHAR(64) NULL UNIQUE,
  notes TEXT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_tenancy_due (tenancy_id, category),
  CONSTRAINT fk_due_tenancy FOREIGN KEY (tenancy_id) REFERENCES tenancies(id)
);

CREATE TABLE bills (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id BIGINT UNSIGNED NULL,
  tenancy_id BIGINT UNSIGNED NULL,
  bill_date DATE NOT NULL,
  description VARCHAR(200) NOT NULL,
  amount DECIMAL(12,2) NOT NULL,
  vat_amount DECIMAL(12,2) NOT NULL DEFAULT 0,
  total_amount DECIMAL(12,2) NOT NULL,
  status ENUM('Draft','Pending','Paid') NOT NULL DEFAULT 'Draft',
  paid_at DATE NULL,
  receipt_no VARCHAR(64) NULL UNIQUE,
  notes TEXT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_bill_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id),
  CONSTRAINT fk_bill_tenancy FOREIGN KEY (tenancy_id) REFERENCES tenancies(id)
);
