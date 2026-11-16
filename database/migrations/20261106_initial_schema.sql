-- Original schema before the incremental migrations. Uses the configured database.
CREATE TABLE IF NOT EXISTS users (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(120) NOT NULL,
  username VARCHAR(80) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  role ENUM('admin','staff') NOT NULL DEFAULT 'staff',
  active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS properties (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(180) NOT NULL,
  code VARCHAR(60) NOT NULL UNIQUE,
  emirate VARCHAR(80) NOT NULL,
  area VARCHAR(120) NOT NULL,
  owner_name VARCHAR(160) NOT NULL,
  owner_contact VARCHAR(60) NULL,
  type ENUM('Residential','Commercial','Land','Shed','Warehouse','Other') NOT NULL DEFAULT 'Residential',
  address TEXT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_location (emirate, area), INDEX idx_owner (owner_name)
);
CREATE TABLE IF NOT EXISTS units (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  property_id BIGINT UNSIGNED NOT NULL,
  room_number VARCHAR(60) NOT NULL,
  bedrooms VARCHAR(30) NOT NULL DEFAULT 'Studio',
  bathrooms SMALLINT UNSIGNED NOT NULL DEFAULT 1,
  floor_label VARCHAR(40) NULL,
  occupancy ENUM('Family','Bachelor','Both') NOT NULL DEFAULT 'Both',
  photo_path VARCHAR(255) NULL,
  UNIQUE KEY uq_property_room (property_id, room_number),
  CONSTRAINT fk_unit_property FOREIGN KEY (property_id) REFERENCES properties(id)
);
CREATE TABLE IF NOT EXISTS tenants (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(160) NOT NULL,
  nationality VARCHAR(100) NULL,
  vat_id VARCHAR(80) NULL,
  identity_number VARCHAR(100) NULL,
  contact VARCHAR(60) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_tenant_contact (contact), INDEX idx_tenant_name (name)
);
CREATE TABLE IF NOT EXISTS tenancies (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  unit_id BIGINT UNSIGNED NOT NULL,
  tenant_id BIGINT UNSIGNED NOT NULL,
  purpose ENUM('Family','Bachelor') NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  free_months TINYINT UNSIGNED NOT NULL DEFAULT 0,
  yearly_rent DECIMAL(12,2) NOT NULL,
  payment_mode ENUM('Cash','Cheque') NOT NULL,
  commission_amount DECIMAL(12,2) NOT NULL DEFAULT 0,
  security_amount DECIMAL(12,2) NOT NULL DEFAULT 0,
  sewa_account VARCHAR(100) NULL,
  notes TEXT NULL,
  agreement_path VARCHAR(255) NULL,
  status ENUM('Active','Renewed','Cancelled','Expired') NOT NULL DEFAULT 'Active',
  cancelled_at DATE NULL,
  cancellation_agreement_path VARCHAR(255) NULL,
  sewa_bill_path VARCHAR(255) NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_tenancy_unit FOREIGN KEY (unit_id) REFERENCES units(id),
  CONSTRAINT fk_tenancy_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id),
  INDEX idx_tenancy_dates (start_date,end_date,status)
);
CREATE TABLE IF NOT EXISTS cheques (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenancy_id BIGINT UNSIGNED NOT NULL,
  cheque_number VARCHAR(100) NOT NULL,
  bank_name VARCHAR(120) NOT NULL,
  cheque_date DATE NOT NULL,
  amount DECIMAL(12,2) NOT NULL,
  holder_name VARCHAR(160) NOT NULL,
  cleared BOOLEAN NOT NULL DEFAULT FALSE,
  cleared_at DATE NULL,
  CONSTRAINT fk_cheque_tenancy FOREIGN KEY (tenancy_id) REFERENCES tenancies(id) ON DELETE CASCADE,
  INDEX idx_cheque_date (cheque_date), INDEX idx_cheque_bank (bank_name)
);


CREATE TABLE IF NOT EXISTS tenancy_renewals (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenancy_id BIGINT UNSIGNED NOT NULL,
  previous_start_date DATE NOT NULL,
  previous_end_date DATE NOT NULL,
  new_start_date DATE NOT NULL,
  new_end_date DATE NOT NULL,
  new_yearly_rent DECIMAL(12,2) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_renewal_tenancy FOREIGN KEY (tenancy_id) REFERENCES tenancies(id)
);

-- Initial admin login: admin / ChangeMe123! — change immediately after setup.
INSERT IGNORE INTO users (name, username, password_hash, role)
VALUES ('Fora Administrator', 'admin', '$2y$10$mSj7TDnw3sfzw/Scuxx7KeSe.5nA/O3YKJG/Z0VNiT2ip8IYbmmTy', 'admin');
