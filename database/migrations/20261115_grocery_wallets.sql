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
