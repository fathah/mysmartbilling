ALTER TABLE mobile_purchases
  ADD COLUMN payment_mode ENUM('Cash','Credit') NOT NULL DEFAULT 'Cash' AFTER balance_amount,
  ADD COLUMN payment_method ENUM('Cash','Card','Bank') NULL AFTER payment_mode;