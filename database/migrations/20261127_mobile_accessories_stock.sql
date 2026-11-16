ALTER TABLE mobile_inventory
  MODIFY inventory_type ENUM('new','used','accessory') NOT NULL,
  ADD COLUMN item_category VARCHAR(60) NOT NULL DEFAULT 'Mobile' AFTER item_name,
  ADD COLUMN quantity INT UNSIGNED NOT NULL DEFAULT 1 AFTER stock_status,
  MODIFY model VARCHAR(160) NULL,
  MODIFY model_year SMALLINT UNSIGNED NULL,
  MODIFY imei_number VARCHAR(100) NULL;

UPDATE mobile_inventory SET item_category=CASE inventory_type WHEN 'new' THEN 'New mobile' WHEN 'used' THEN 'Used mobile' ELSE 'Other' END WHERE item_category='Mobile';

ALTER TABLE mobile_sales
  MODIFY inventory_type ENUM('new','used','accessory') NOT NULL,
  ADD COLUMN item_category VARCHAR(60) NOT NULL DEFAULT 'Mobile' AFTER item_name,
  ADD COLUMN quantity INT UNSIGNED NOT NULL DEFAULT 1 AFTER imei_number,
  MODIFY model VARCHAR(160) NULL,
  MODIFY model_year SMALLINT UNSIGNED NULL,
  MODIFY imei_number VARCHAR(100) NULL;

ALTER TABLE mobile_purchase_lines
  MODIFY model VARCHAR(160) NULL,
  MODIFY model_year SMALLINT UNSIGNED NULL;
