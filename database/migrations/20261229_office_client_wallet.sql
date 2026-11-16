CREATE TABLE IF NOT EXISTS office_bill_payments (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  company_id BIGINT UNSIGNED NOT NULL,
  bill_id BIGINT UNSIGNED NOT NULL,
  payment_key VARCHAR(60) NOT NULL,
  payment_date DATE NOT NULL,
  amount DECIMAL(12,2) NOT NULL,
  payment_method VARCHAR(30) NOT NULL,
  payment_reference VARCHAR(120) NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_office_bill_payment_key(company_id,bill_id,payment_key),
  INDEX idx_office_bill_payments_date(company_id,payment_date),
  CONSTRAINT fk_office_bill_payments_company FOREIGN KEY(company_id) REFERENCES companies(id) ON DELETE CASCADE,
  CONSTRAINT fk_office_bill_payments_bill FOREIGN KEY(bill_id) REFERENCES office_bills(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT IGNORE INTO office_bill_payments(company_id,bill_id,payment_key,payment_date,amount,payment_method,payment_reference)
SELECT company_id,id,CONCAT('INITIAL-',id),bill_date,paid_amount,payment_method,payment_reference
FROM office_bills b WHERE b.paid_amount>0 AND NOT EXISTS (SELECT 1 FROM office_bill_payments p WHERE p.company_id=b.company_id AND p.bill_id=b.id AND p.payment_key LIKE 'PAY-%');