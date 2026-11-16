ALTER TABLE tenancies
  ADD COLUMN vat_rate DECIMAL(4,2) NOT NULL DEFAULT 5.00 AFTER vat_amount,
  ADD COLUMN vat_treatment ENUM('Standard Rated','Zero Rated','Exempt') NOT NULL DEFAULT 'Standard Rated' AFTER vat_rate;

UPDATE tenancies tn
JOIN units u ON u.id=tn.unit_id
JOIN properties p ON p.id=u.property_id
SET tn.vat_rate=CASE WHEN LOWER(TRIM(p.type)) IN ('residential','land') THEN 0.00 ELSE 5.00 END,
    tn.vat_treatment=CASE WHEN LOWER(TRIM(p.type)) IN ('residential','land') THEN 'Exempt' ELSE 'Standard Rated' END,
    tn.vat_amount=ROUND(tn.yearly_rent*CASE WHEN LOWER(TRIM(p.type)) IN ('residential','land') THEN 0 ELSE 0.05 END,2),
    tn.total_amount=tn.yearly_rent+ROUND(tn.yearly_rent*CASE WHEN LOWER(TRIM(p.type)) IN ('residential','land') THEN 0 ELSE 0.05 END,2);