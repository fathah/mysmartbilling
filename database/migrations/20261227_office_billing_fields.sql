ALTER TABLE office_bills
  ADD COLUMN vat_rate DECIMAL(5,2) NOT NULL DEFAULT 5.00 AFTER gov_fee_total,
  ADD COLUMN vat_amount DECIMAL(12,2) NOT NULL DEFAULT 0 AFTER vat_rate,
  ADD COLUMN discount_amount DECIMAL(12,2) NOT NULL DEFAULT 0 AFTER vat_amount,
  ADD COLUMN paid_amount DECIMAL(12,2) NOT NULL DEFAULT 0 AFTER total_amount,
  ADD COLUMN balance_amount DECIMAL(12,2) NOT NULL DEFAULT 0 AFTER paid_amount,
  ADD COLUMN payment_mode VARCHAR(30) NOT NULL DEFAULT 'Cash' AFTER balance_amount,
  ADD COLUMN payment_method VARCHAR(30) NOT NULL DEFAULT 'Cash' AFTER payment_mode,
  ADD COLUMN payment_reference VARCHAR(120) NULL AFTER payment_method,
  ADD COLUMN notes VARCHAR(500) NULL AFTER payment_reference;

ALTER TABLE office_bill_lines
  ADD COLUMN service_charge DECIMAL(12,2) NOT NULL DEFAULT 0 AFTER gov_fee,
  ADD COLUMN vat_rate DECIMAL(5,2) NOT NULL DEFAULT 5.00 AFTER service_charge,
  ADD COLUMN vat_amount DECIMAL(12,2) NOT NULL DEFAULT 0 AFTER vat_rate,
  ADD COLUMN grand_total DECIMAL(12,2) NOT NULL DEFAULT 0 AFTER line_total;
