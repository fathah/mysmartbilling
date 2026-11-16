ALTER TABLE companies ADD COLUMN sales_vat_rate DECIMAL(5,2) NOT NULL DEFAULT 5.00 AFTER sales_bill_color;
ALTER TABLE mobile_sales ADD COLUMN base_amount DECIMAL(12,2) NULL AFTER quantity, ADD COLUMN vat_rate DECIMAL(5,2) NOT NULL DEFAULT 0.00 AFTER base_amount, ADD COLUMN vat_amount DECIMAL(12,2) NOT NULL DEFAULT 0.00 AFTER vat_rate, ADD COLUMN discount_amount DECIMAL(12,2) NOT NULL DEFAULT 0.00 AFTER vat_amount;
UPDATE mobile_sales SET base_amount=sale_amount WHERE base_amount IS NULL;
