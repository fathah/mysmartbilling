
ALTER TABLE grocery_sales
  ADD COLUMN vat_mode ENUM('Inclusive','Exclusive') NULL AFTER vat_amount;

-- Preserve the historical exclusive-price behavior for bills saved before this setting existed.
UPDATE grocery_sales SET vat_mode='Exclusive' WHERE vat_mode IS NULL;

ALTER TABLE grocery_sales
  MODIFY COLUMN vat_mode ENUM('Inclusive','Exclusive') NOT NULL DEFAULT 'Inclusive';
