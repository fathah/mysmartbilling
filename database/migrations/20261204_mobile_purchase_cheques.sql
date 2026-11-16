ALTER TABLE mobile_purchases
  MODIFY payment_method ENUM('Cash','Card','Bank','Cheque') NULL;

ALTER TABLE mobile_supplier_payments
  MODIFY payment_method ENUM('Cash','Card','Bank','Transfer','Cheque') NOT NULL DEFAULT 'Cash';