ALTER TABLE companies
  ADD COLUMN paid_amount DECIMAL(12,2) NOT NULL DEFAULT 0.00 AFTER subscription_mode,
  ADD COLUMN bill_number VARCHAR(100) NULL AFTER paid_amount,
  ADD COLUMN bank_transfer_details VARCHAR(500) NULL AFTER bill_number;
