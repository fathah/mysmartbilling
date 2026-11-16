-- Run once after 20261109_rent_vat_billing.sql.
ALTER TABLE contract_dues
  ADD COLUMN bill_date DATE NULL AFTER category,
  ADD COLUMN description VARCHAR(200) NULL AFTER bill_date,
  ADD COLUMN vat_amount DECIMAL(12,2) NOT NULL DEFAULT 0 AFTER amount,
  ADD COLUMN total_amount DECIMAL(12,2) NOT NULL DEFAULT 0 AFTER vat_amount;

UPDATE contract_dues d
JOIN tenancies t ON t.id=d.tenancy_id
SET d.bill_date=t.contract_date,
    d.description=CONCAT(d.category,' receipt'),
    d.vat_amount=ROUND(d.amount*0.05,2),
    d.total_amount=d.amount+ROUND(d.amount*0.05,2)
WHERE d.bill_date IS NULL OR d.description IS NULL;

ALTER TABLE contract_dues
  MODIFY bill_date DATE NOT NULL,
  MODIFY description VARCHAR(200) NOT NULL;
