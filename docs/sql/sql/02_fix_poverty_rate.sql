ALTER TABLE homeless_merged_enriched DROP COLUMN IF EXISTS poverty_rate;
ALTER TABLE homeless_merged_enriched ADD COLUMN poverty_rate DOUBLE;
UPDATE homeless_merged_enriched
SET poverty_rate = CAST(value_percent AS DOUBLE) / 100.0;
