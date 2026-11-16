ALTER TABLE mobile_purchases
  ADD COLUMN subtotal_amount DECIMAL(12,2) NOT NULL DEFAULT 0.00 AFTER supplier_contact,
  ADD COLUMN vat_treatment VARCHAR(32) NOT NULL DEFAULT 'Unrecorded' AFTER subtotal_amount,
  ADD COLUMN vat_rate DECIMAL(5,2) NOT NULL DEFAULT 0.00 AFTER vat_treatment,
  ADD COLUMN vat_amount DECIMAL(12,2) NOT NULL DEFAULT 0.00 AFTER vat_rate;

UPDATE mobile_purchases
SET subtotal_amount=total_amount
WHERE subtotal_amount=0.00;