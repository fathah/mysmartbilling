ALTER TABLE mobile_sales
  ADD COLUMN salesman_code VARCHAR(80) NOT NULL DEFAULT '' AFTER customer_id;

ALTER TABLE mobile_purchases
  ADD COLUMN salesman_code VARCHAR(80) NOT NULL DEFAULT '' AFTER payment_method;
