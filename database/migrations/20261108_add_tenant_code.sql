-- Run after 20261107_preserve_renewal_history.sql on an existing installation.
ALTER TABLE tenants ADD COLUMN code VARCHAR(24) NULL AFTER id;
UPDATE tenants SET code=CONCAT('FORA-', LPAD(id, 8, '0')) WHERE code IS NULL;
ALTER TABLE tenants
  MODIFY code VARCHAR(24) NOT NULL,
  ADD UNIQUE KEY uq_tenant_code (code);
