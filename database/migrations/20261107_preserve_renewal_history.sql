-- Run once against an existing myshop database before deploying this version.
-- Existing tenancy_renewals rows remain intact; previous_tenancy_id is NULL for
-- those legacy rows because the old flow overwrote the original tenancy record.
ALTER TABLE tenancies
  MODIFY status ENUM('Active','Renewed','Cancelled','Expired') NOT NULL DEFAULT 'Active',
  ADD COLUMN previous_tenancy_id BIGINT UNSIGNED NULL AFTER tenant_id,
  ADD CONSTRAINT fk_tenancy_previous FOREIGN KEY (previous_tenancy_id) REFERENCES tenancies(id);

ALTER TABLE tenancy_renewals
  ADD COLUMN previous_tenancy_id BIGINT UNSIGNED NULL AFTER tenancy_id,
  ADD CONSTRAINT fk_renewal_previous FOREIGN KEY (previous_tenancy_id) REFERENCES tenancies(id);
