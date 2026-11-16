ALTER TABLE companies
  ADD COLUMN arabic_trade_name VARCHAR(180) NULL AFTER trade_name,
  ADD COLUMN address_arabic VARCHAR(500) NULL AFTER address,
  ADD COLUMN corporate_tax_period_start DATE NULL AFTER sales_vat_rate,
  ADD COLUMN corporate_tax_period_end DATE NULL AFTER corporate_tax_period_start;
