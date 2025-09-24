Stats Lab (csvfiddle/DuckDB)

Explore how county poverty relates to homelessness levels, types, and variability.

Data

homeless_merged_enriched — includes quarterly totals, type breakdowns, and poverty (% and people).

# Setup: build a tidy metrics table 
DROP TABLE IF EXISTS homeless_metrics;

CREATE TABLE homeless_metrics AS
WITH base AS (
  SELECT
    county_id, county_name,
    q1,q2,q3,q4,
    shelter_transitional, doubled_up, unsheltered, hotels_motels,
    unaccompanied_youth, not_applicable, total_enrollment,
    CAST(value_percent AS DOUBLE) AS value_percent,
    CAST(people_below_poverty AS DOUBLE) AS people_below_poverty,
    CAST(value_percent AS DOUBLE)/100.0 AS poverty_rate
  FROM homeless_merged_enriched
),
rates AS (
  SELECT
    *,
    CASE WHEN people_below_poverty>0
         THEN 1000.0*total_enrollment/people_below_poverty END AS homeless_per_1k_poverty,
    CASE WHEN total_enrollment>0 THEN 1.0*unsheltered/total_enrollment END AS share_unsheltered,
    CASE WHEN total_enrollment>0 THEN 1.0*shelter_transitional/total_enrollment END AS share_sheltered
  FROM base
),
v AS (
  SELECT
    county_name,
    (q1+q2+q3+q4)/4.0 AS mean_q,
    (
      ((q1-((q1+q2+q3+q4)/4.0))*(q1-((q1+q2+q3+q4)/4.0)) +
       (q2-((q1+q2+q3+q4)/4.0))*(q2-((q1+q2+q3+q4)/4.0)) +
       (q3-((q1+q2+q3+q4)/4.0))*(q3-((q1+q2+q3+q4)/4.0)) +
       (q4-((q1+q2+q3+q4)/4.0))*(q4-((q1+q2+q3+q4)/4.0)) )/3.0
    ) AS var_q
  FROM base
),
cv AS (
  SELECT county_name, ROUND(100*SQRT(var_q)/NULLIF(mean_q,0),1) AS cv_percent
  FROM v
),
w AS (
  SELECT r.*,
         NTILE(4) OVER (ORDER BY value_percent) AS pov_quartile
  FROM rates r
)
SELECT w.*, cv.cv_percent
FROM w LEFT JOIN cv USING (county_name);

# Descriptives
SELECT
  COUNT(*) AS n_counties,
  ROUND(AVG(value_percent),2) AS mean_poverty_pct,
  ROUND(quantile_cont(value_percent,0.5),2) AS median_poverty_pct,
  ROUND(stddev_samp(value_percent),2) AS sd_poverty_pct,
  ROUND(AVG(total_enrollment),1) AS mean_homeless_count
FROM homeless_metrics;

# Correlation: poverty vs. counts vs. rates
SELECT
  corr(value_percent, total_enrollment)        AS r_poverty_count,
  corr(value_percent, homeless_per_1k_poverty) AS r_poverty_rate;


## Talking point: counts confound size; rates compare fairly.

# Quartiles of poverty → average homeless rate
SELECT pov_quartile,
       ROUND(AVG(homeless_per_1k_poverty),2) AS mean_rate_per_1k,
       COUNT(*) AS n
FROM homeless_metrics
GROUP BY 1 ORDER BY 1;

# Composition (unsheltered share by poverty quartile)
SELECT pov_quartile,
       ROUND(AVG(share_unsheltered),3) AS avg_unsheltered_share
FROM homeless_metrics
GROUP BY 1 ORDER BY 1;

# Variability across quarters (top CV%)
SELECT county_name, cv_percent
FROM homeless_metrics
ORDER BY cv_percent DESC NULLS LAST
LIMIT 10;

# Outliers: highest rates given poverty
SELECT county_name,
       ROUND(value_percent,1) AS poverty_pct,
       ROUND(homeless_per_1k_poverty,2) AS rate_per_1k
FROM homeless_metrics
ORDER BY rate_per_1k DESC NULLS LAST
LIMIT 10;
