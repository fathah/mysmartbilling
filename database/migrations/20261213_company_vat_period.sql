ALTER TABLE companies
  ADD COLUMN vat_period_start DATE NULL AFTER sales_vat_rate,
  ADD COLUMN vat_period_end DATE NULL AFTER vat_period_start;
