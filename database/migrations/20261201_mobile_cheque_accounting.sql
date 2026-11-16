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

-- Keep the cheque register to one bank movement per cleared cheque.
DELETE e FROM mobile_account_entries e
LEFT JOIN mobile_cheques c ON c.id=e.reference_id AND c.company_id=e.company_id
WHERE e.reference_type='mobile_cheque'
  AND (c.id IS NULL OR c.status<>'Cleared' OR e.account_name<>CONCAT('Bank - ',c.bank_name));

UPDATE mobile_account_entries e
JOIN mobile_cheques c ON c.id=e.reference_id AND c.company_id=e.company_id
SET e.entry_date=COALESCE(c.status_date,CURDATE()),
    e.account_name=CONCAT('Bank - ',c.bank_name),
    e.debit_amount=IF(c.cheque_direction='Outgoing',c.amount,0),
    e.credit_amount=IF(c.cheque_direction='Incoming',c.amount,0),
    e.reference_number=c.cheque_number,
    e.description=CONCAT(IF(c.cheque_direction='Incoming','Incoming cheque cleared','Outgoing cheque cleared'),' · ',c.cheque_holder,' · ',c.purpose),
    e.contra_account=c.purpose
WHERE c.status='Cleared';

INSERT IGNORE INTO mobile_account_entries(company_id,entry_date,account_name,debit_amount,credit_amount,reference_type,reference_id,reference_number,description,contra_account)
SELECT c.company_id,COALESCE(c.status_date,CURDATE()),CONCAT('Bank - ',c.bank_name),
       IF(c.cheque_direction='Outgoing',c.amount,0),IF(c.cheque_direction='Incoming',c.amount,0),
       'mobile_cheque',c.id,c.cheque_number,
       CONCAT(IF(c.cheque_direction='Incoming','Incoming cheque cleared','Outgoing cheque cleared'),' · ',c.cheque_holder,' · ',c.purpose),c.purpose
FROM mobile_cheques c WHERE c.status='Cleared';