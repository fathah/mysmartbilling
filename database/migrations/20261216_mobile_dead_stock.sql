ALTER TABLE mobile_inventory
  MODIFY stock_status ENUM('In Stock','Reserved','Sold','Dead Stock') NOT NULL DEFAULT 'In Stock',
  ADD COLUMN dead_stock_reason ENUM('Damaged','Obsolete') NULL AFTER quantity,
  ADD COLUMN dead_stock_date DATE NULL AFTER dead_stock_reason,
  ADD COLUMN dead_stock_notes VARCHAR(500) NULL AFTER dead_stock_date;
