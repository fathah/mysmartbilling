CREATE DATABASE IF NOT EXISTS myshop CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE myshop;

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
  code VARCHAR(24) NOT NULL UNIQUE,
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
  previous_tenancy_id BIGINT UNSIGNED NULL,
  contract_date DATE NOT NULL,
  purpose ENUM('Family','Bachelor') NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  free_months TINYINT UNSIGNED NOT NULL DEFAULT 0,
  yearly_rent DECIMAL(12,2) NOT NULL,
  vat_amount DECIMAL(12,2) NOT NULL DEFAULT 0,
  vat_rate DECIMAL(4,2) NOT NULL DEFAULT 5.00,
  vat_treatment ENUM('Standard Rated','Zero Rated','Exempt') NOT NULL DEFAULT 'Standard Rated',
  total_amount DECIMAL(12,2) NOT NULL DEFAULT 0,
  first_payment_cash DECIMAL(12,2) NOT NULL DEFAULT 0,
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
  CONSTRAINT fk_tenancy_previous FOREIGN KEY (previous_tenancy_id) REFERENCES tenancies(id),
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
  INDEX idx_cheque_date (cheque_date), INDEX idx_cheque_bank (bank_name),
  UNIQUE KEY uq_cheque_bank_number (bank_name,cheque_number)
);
CREATE TABLE IF NOT EXISTS contract_dues (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenancy_id BIGINT UNSIGNED NOT NULL,
  category ENUM('Commission','Security') NOT NULL,
  bill_date DATE NOT NULL,
  description VARCHAR(200) NOT NULL,
  amount DECIMAL(12,2) NOT NULL DEFAULT 0,
  vat_amount DECIMAL(12,2) NOT NULL DEFAULT 0,
  total_amount DECIMAL(12,2) NOT NULL DEFAULT 0,
  status ENUM('Draft','Pending','Paid') NOT NULL DEFAULT 'Draft',
  paid_at DATE NULL,
  receipt_no VARCHAR(64) NULL UNIQUE,
  notes TEXT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_tenancy_due (tenancy_id, category),
  CONSTRAINT fk_due_tenancy FOREIGN KEY (tenancy_id) REFERENCES tenancies(id)
);
CREATE TABLE IF NOT EXISTS bills (
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
CREATE TABLE IF NOT EXISTS tenancy_renewals (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenancy_id BIGINT UNSIGNED NOT NULL,
  previous_tenancy_id BIGINT UNSIGNED NOT NULL,
  previous_start_date DATE NOT NULL,
  previous_end_date DATE NOT NULL,
  new_start_date DATE NOT NULL,
  new_end_date DATE NOT NULL,
  new_yearly_rent DECIMAL(12,2) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_renewal_tenancy FOREIGN KEY (tenancy_id) REFERENCES tenancies(id),
  CONSTRAINT fk_renewal_previous FOREIGN KEY (previous_tenancy_id) REFERENCES tenancies(id)
);

-- Initial admin login: admin / ChangeMe123! — change immediately after setup.
INSERT IGNORE INTO users (name, username, password_hash, role)
VALUES ('Fora Administrator', 'admin', '$2y$10$mSj7TDnw3sfzw/Scuxx7KeSe.5nA/O3YKJG/Z0VNiT2ip8IYbmmTy', 'admin');


-- Balanced debit and credit entries created when Mobile cheques are cleared.
CREATE TABLE IF NOT EXISTS mobile_account_entries (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  company_id BIGINT UNSIGNED NOT NULL,
  entry_date DATE NOT NULL,
  account_name VARCHAR(180) NOT NULL,
  debit_amount DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  credit_amount DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  reference_type VARCHAR(40) NOT NULL,
  reference_id BIGINT UNSIGNED NOT NULL,
  reference_number VARCHAR(100) NOT NULL,
  description VARCHAR(500) NOT NULL,
  contra_account VARCHAR(180) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_mobile_account_source_side(company_id,reference_type,reference_id,account_name),
  INDEX idx_mobile_account_company_date(company_id,entry_date),
  CONSTRAINT fk_mobile_account_company FOREIGN KEY(company_id) REFERENCES companies(id) ON DELETE CASCADE
);

-- Transfers from shop cash to a bank account.
CREATE TABLE IF NOT EXISTS mobile_wallet_transfers (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  company_id BIGINT UNSIGNED NOT NULL,
  transfer_date DATE NOT NULL,
  bank_account VARCHAR(160) NOT NULL,
  amount DECIMAL(12,2) NOT NULL,
  reference VARCHAR(160) NULL,
  notes VARCHAR(500) NULL,
  created_by BIGINT UNSIGNED NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_wallet_transfer_company_date(company_id,transfer_date),
  CONSTRAINT fk_wallet_transfer_company FOREIGN KEY(company_id) REFERENCES companies(id) ON DELETE CASCADE,
  CONSTRAINT fk_wallet_transfer_user FOREIGN KEY(created_by) REFERENCES users(id)
);

-- Grocery retail tables
CREATE TABLE IF NOT EXISTS grocery_products (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  company_id BIGINT UNSIGNED NOT NULL,
  product_code VARCHAR(40) NOT NULL,
  barcode VARCHAR(100) NULL,
  product_name VARCHAR(180) NOT NULL,
  category VARCHAR(100) NOT NULL DEFAULT 'General',
  brand VARCHAR(120) NULL,
  unit_name VARCHAR(40) NOT NULL DEFAULT 'Piece',
  description VARCHAR(500) NULL,
  cost_price DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  sale_price DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  vat_rate DECIMAL(5,2) NOT NULL DEFAULT 5.00,
  current_stock DECIMAL(12,3) NOT NULL DEFAULT 0.000,
  minimum_stock DECIMAL(12,3) NOT NULL DEFAULT 0.000,
  expiry_date DATE NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_by BIGINT UNSIGNED NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_grocery_company_product_code(company_id,product_code),
  UNIQUE KEY uq_grocery_company_barcode(company_id,barcode),
  INDEX idx_grocery_products_company_name(company_id,product_name),
  INDEX idx_grocery_products_stock(company_id,current_stock),
  INDEX idx_grocery_products_expiry(company_id,expiry_date),
  CONSTRAINT fk_grocery_products_company FOREIGN KEY(company_id) REFERENCES companies(id) ON DELETE CASCADE,
  CONSTRAINT fk_grocery_products_user FOREIGN KEY(created_by) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS grocery_customers (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  company_id BIGINT UNSIGNED NOT NULL,
  customer_name VARCHAR(180) NOT NULL,
  building_flat VARCHAR(180) NULL,
  mobile VARCHAR(30) NULL,
  email VARCHAR(180) NULL,
  trn VARCHAR(30) NULL,
  address VARCHAR(500) NULL,
  notes VARCHAR(500) NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_grocery_customers_name(company_id,customer_name),
  INDEX idx_grocery_customers_mobile(company_id,mobile),
  CONSTRAINT fk_grocery_customers_company FOREIGN KEY(company_id) REFERENCES companies(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS grocery_suppliers (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  company_id BIGINT UNSIGNED NOT NULL,
  supplier_name VARCHAR(180) NOT NULL,
  contact_person VARCHAR(160) NULL,
  mobile VARCHAR(30) NULL,
  email VARCHAR(180) NULL,
  trn VARCHAR(30) NULL,
  address VARCHAR(500) NULL,
  notes VARCHAR(500) NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_grocery_suppliers_name(company_id,supplier_name),
  INDEX idx_grocery_suppliers_mobile(company_id,mobile),
  CONSTRAINT fk_grocery_suppliers_company FOREIGN KEY(company_id) REFERENCES companies(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS grocery_sales (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  company_id BIGINT UNSIGNED NOT NULL,
  bill_number VARCHAR(40) NOT NULL,
  sale_date DATE NOT NULL,
  customer_id BIGINT UNSIGNED NULL,
  subtotal_amount DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  vat_amount DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  discount_amount DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  total_amount DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  amount_paid DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  balance_amount DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  payment_mode ENUM('Cash','Credit') NOT NULL DEFAULT 'Cash',
  payment_method VARCHAR(30) NULL,
  payment_reference VARCHAR(160) NULL,
  notes VARCHAR(500) NULL,
  created_by BIGINT UNSIGNED NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_grocery_sales_bill(company_id,bill_number),
  INDEX idx_grocery_sales_company_date(company_id,sale_date),
  INDEX idx_grocery_sales_customer(company_id,customer_id),
  CONSTRAINT fk_grocery_sales_company FOREIGN KEY(company_id) REFERENCES companies(id) ON DELETE CASCADE,
  CONSTRAINT fk_grocery_sales_customer FOREIGN KEY(customer_id) REFERENCES grocery_customers(id) ON DELETE SET NULL,
  CONSTRAINT fk_grocery_sales_user FOREIGN KEY(created_by) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS grocery_sale_items (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  company_id BIGINT UNSIGNED NOT NULL,
  sale_id BIGINT UNSIGNED NOT NULL,
  product_id BIGINT UNSIGNED NOT NULL,
  product_name VARCHAR(180) NOT NULL,
  barcode VARCHAR(100) NULL,
  unit_name VARCHAR(40) NOT NULL,
  quantity DECIMAL(12,3) NOT NULL,
  unit_price DECIMAL(12,2) NOT NULL,
  unit_cost DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  vat_rate DECIMAL(5,2) NOT NULL DEFAULT 0.00,
  vat_amount DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  line_total DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  INDEX idx_grocery_sale_items_sale(company_id,sale_id),
  INDEX idx_grocery_sale_items_product(company_id,product_id),
  CONSTRAINT fk_grocery_sale_items_company FOREIGN KEY(company_id) REFERENCES companies(id) ON DELETE CASCADE,
  CONSTRAINT fk_grocery_sale_items_sale FOREIGN KEY(sale_id) REFERENCES grocery_sales(id) ON DELETE CASCADE,
  CONSTRAINT fk_grocery_sale_items_product FOREIGN KEY(product_id) REFERENCES grocery_products(id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS grocery_purchases (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  company_id BIGINT UNSIGNED NOT NULL,
  purchase_number VARCHAR(40) NOT NULL,
  supplier_id BIGINT UNSIGNED NOT NULL,
  supplier_invoice_number VARCHAR(100) NOT NULL,
  purchase_date DATE NOT NULL,
  due_date DATE NULL,
  subtotal_amount DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  vat_amount DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  total_amount DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  amount_paid DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  balance_amount DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  payment_mode ENUM('Cash','Credit') NOT NULL DEFAULT 'Cash',
  payment_method VARCHAR(30) NULL,
  payment_reference VARCHAR(160) NULL,
  notes VARCHAR(500) NULL,
  created_by BIGINT UNSIGNED NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_grocery_purchases_number(company_id,purchase_number),
  INDEX idx_grocery_purchases_company_date(company_id,purchase_date),
  INDEX idx_grocery_purchases_supplier(company_id,supplier_id),
  CONSTRAINT fk_grocery_purchases_company FOREIGN KEY(company_id) REFERENCES companies(id) ON DELETE CASCADE,
  CONSTRAINT fk_grocery_purchases_supplier FOREIGN KEY(supplier_id) REFERENCES grocery_suppliers(id) ON DELETE RESTRICT,
  CONSTRAINT fk_grocery_purchases_user FOREIGN KEY(created_by) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS grocery_purchase_items (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  company_id BIGINT UNSIGNED NOT NULL,
  purchase_id BIGINT UNSIGNED NOT NULL,
  product_id BIGINT UNSIGNED NOT NULL,
  product_name VARCHAR(180) NOT NULL,
  barcode VARCHAR(100) NULL,
  unit_name VARCHAR(40) NOT NULL,
  quantity DECIMAL(12,3) NOT NULL,
  unit_cost DECIMAL(12,2) NOT NULL,
  vat_rate DECIMAL(5,2) NOT NULL DEFAULT 0.00,
  vat_amount DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  line_total DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  expiry_date DATE NULL,
  INDEX idx_grocery_purchase_items_purchase(company_id,purchase_id),
  INDEX idx_grocery_purchase_items_product(company_id,product_id),
  CONSTRAINT fk_grocery_purchase_items_company FOREIGN KEY(company_id) REFERENCES companies(id) ON DELETE CASCADE,
  CONSTRAINT fk_grocery_purchase_items_purchase FOREIGN KEY(purchase_id) REFERENCES grocery_purchases(id) ON DELETE CASCADE,
  CONSTRAINT fk_grocery_purchase_items_product FOREIGN KEY(product_id) REFERENCES grocery_products(id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS grocery_expenses (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  company_id BIGINT UNSIGNED NOT NULL,
  expense_date DATE NOT NULL,
  expense_name VARCHAR(180) NOT NULL,
  description VARCHAR(500) NULL,
  trn VARCHAR(30) NULL,
  amount DECIMAL(12,2) NOT NULL,
  payment_method VARCHAR(30) NOT NULL DEFAULT 'Cash',
  reference VARCHAR(160) NULL,
  created_by BIGINT UNSIGNED NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_grocery_expenses_company_date(company_id,expense_date),
  CONSTRAINT fk_grocery_expenses_company FOREIGN KEY(company_id) REFERENCES companies(id) ON DELETE CASCADE,
  CONSTRAINT fk_grocery_expenses_user FOREIGN KEY(created_by) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
USE myshop;
CREATE TABLE IF NOT EXISTS grocery_customer_payments (
 id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
 company_id BIGINT UNSIGNED NOT NULL,
 sale_id BIGINT UNSIGNED NOT NULL,
 payment_date DATE NOT NULL,
 amount DECIMAL(12,2) NOT NULL,
 payment_method VARCHAR(30) NOT NULL,
 reference VARCHAR(160) NULL,
 received_by BIGINT UNSIGNED NULL,
 created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
 INDEX idx_grocery_customer_payments_bill(company_id,sale_id,payment_date),
 CONSTRAINT fk_grocery_customer_payments_company FOREIGN KEY(company_id) REFERENCES companies(id) ON DELETE CASCADE,
 CONSTRAINT fk_grocery_customer_payments_sale FOREIGN KEY(sale_id) REFERENCES grocery_sales(id) ON DELETE CASCADE,
 CONSTRAINT fk_grocery_customer_payments_user FOREIGN KEY(received_by) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE IF NOT EXISTS grocery_supplier_payments (
 id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
 company_id BIGINT UNSIGNED NOT NULL,
 purchase_id BIGINT UNSIGNED NOT NULL,
 payment_date DATE NOT NULL,
 amount DECIMAL(12,2) NOT NULL,
 payment_method VARCHAR(30) NOT NULL,
 reference VARCHAR(160) NULL,
 paid_by BIGINT UNSIGNED NULL,
 created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
 INDEX idx_grocery_supplier_payments_bill(company_id,purchase_id,payment_date),
 CONSTRAINT fk_grocery_supplier_payments_company FOREIGN KEY(company_id) REFERENCES companies(id) ON DELETE CASCADE,
 CONSTRAINT fk_grocery_supplier_payments_purchase FOREIGN KEY(purchase_id) REFERENCES grocery_purchases(id) ON DELETE CASCADE,
 CONSTRAINT fk_grocery_supplier_payments_user FOREIGN KEY(paid_by) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
