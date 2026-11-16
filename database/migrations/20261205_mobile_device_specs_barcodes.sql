ALTER TABLE mobile_inventory
  ADD COLUMN ram VARCHAR(20) NULL AFTER model,
  ADD COLUMN storage_capacity VARCHAR(20) NULL AFTER ram,
  ADD COLUMN battery_health VARCHAR(20) NULL AFTER storage_capacity,
  ADD COLUMN serial_barcode VARCHAR(120) NULL AFTER imei_number,
  ADD COLUMN emi_barcode VARCHAR(120) NULL AFTER serial_barcode,
  ADD UNIQUE KEY uq_mobile_inventory_company_serial_barcode(company_id,serial_barcode),
  ADD UNIQUE KEY uq_mobile_inventory_company_emi_barcode(company_id,emi_barcode);

ALTER TABLE mobile_sales
  ADD COLUMN ram VARCHAR(20) NULL AFTER model,
  ADD COLUMN storage_capacity VARCHAR(20) NULL AFTER ram,
  ADD COLUMN battery_health VARCHAR(20) NULL AFTER storage_capacity,
  ADD COLUMN serial_barcode VARCHAR(120) NULL AFTER imei_number,
  ADD COLUMN emi_barcode VARCHAR(120) NULL AFTER serial_barcode;