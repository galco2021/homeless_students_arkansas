DROP TABLE IF EXISTS homeless_merged_enriched;

CREATE TABLE homeless_merged_enriched AS
SELECT
  h.*,
  p.value_percent,
  p.people_below_poverty
FROM homeless_merged AS h
LEFT JOIN (
  SELECT
    UPPER(
      REPLACE(
        REPLACE(
          REPLACE(REPLACE(TRIM("County"), 'Saint ', 'St. '), 'St ', 'St. '),
          ' County',''
        ),
        ' Parish',''
      )
    )                               AS county_name,
    "Value (Percent)"::DOUBLE       AS value_percent,
    "People (Below Poverty)"::INTEGER AS people_below_poverty
  FROM hd_pulse_raw
  WHERE UPPER(TRIM("County")) NOT IN ('UNITED STATES','STATE OF ARKANSAS','ARKANSAS')
) AS p
USING (county_name);
