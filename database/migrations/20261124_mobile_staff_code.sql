ALTER TABLE mobile_staff
  ADD COLUMN staff_code VARCHAR(80) NULL AFTER id;

UPDATE mobile_staff
SET staff_code=CONCAT('STAFF-',LPAD(id,6,'0'))
WHERE staff_code IS NULL OR staff_code='';

ALTER TABLE mobile_staff
  MODIFY staff_code VARCHAR(80) NOT NULL,
  ADD UNIQUE KEY uq_mobile_staff_company_code(company_id,staff_code);
