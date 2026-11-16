ALTER TABLE mobile_purchase_order_lines
  ADD COLUMN brand VARCHAR(100) NULL AFTER item_name,
  ADD COLUMN storage_capacity VARCHAR(20) NULL AFTER model_year,
  ADD COLUMN ram VARCHAR(20) NULL AFTER storage_capacity;

