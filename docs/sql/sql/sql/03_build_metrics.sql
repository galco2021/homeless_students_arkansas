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
