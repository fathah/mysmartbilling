ALTER TABLE mobile_inventory
  ADD COLUMN stock_status ENUM('In Stock','Reserved','Sold') NOT NULL DEFAULT 'In Stock' AFTER imei_number;
