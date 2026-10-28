-- HW06 completion queries for WEATHER_DB.RAW.
-- Run these after HW06_BADGER_setup.sql has created:
--   WEATHER_ANALYSIS_BASE
--   MV_WEATHER_MONTH_CITY
--   MV_WEATHER_YEAR_CLIMATE

USE DATABASE WEATHER_DB;
USE SCHEMA RAW;
USE WAREHOUSE COMPUTE_WH;


-- ============================================================
-- Part 3A: Monthly Weather by City
-- Base-table query. Save/capture this output for the submission.
-- ============================================================
SELECT
    calendar_year,
    month_key,
    month_name,
    city_name,
    state_code,
    AVG(temperature_f) AS avg_temperature_f,
    AVG(apparent_temperature_f) AS avg_apparent_temperature_f,
    SUM(precipitation_in) AS total_precipitation_in,
    AVG(cloud_cover_pct) AS avg_cloud_cover_pct,
    COUNT(*) AS observation_count
FROM weather_analysis_base
GROUP BY
    calendar_year,
    month_key,
    month_name,
    city_name,
    state_code
ORDER BY
    calendar_year,
    month_key,
    city_name;


-- Same query answered from the materialized view.
-- Save/capture this output too.
SELECT
    calendar_year,
    month_key,
    month_name,
    city_name,
    state_code,
    avg_temperature_f,
    avg_apparent_temperature_f,
    total_precipitation_in,
    avg_cloud_cover_pct,
    observation_count
FROM mv_weather_month_city
ORDER BY
    calendar_year,
    month_key,
    city_name;


-- Difference check. Both counts should be 0.
WITH base_result AS (
    SELECT
        calendar_year,
        month_key,
        month_name,
        city_name,
        state_code,
        ROUND(AVG(temperature_f), 6) AS avg_temperature_f,
        ROUND(AVG(apparent_temperature_f), 6) AS avg_apparent_temperature_f,
        ROUND(SUM(precipitation_in), 6) AS total_precipitation_in,
        ROUND(AVG(cloud_cover_pct), 6) AS avg_cloud_cover_pct,
        COUNT(*) AS observation_count
    FROM weather_analysis_base
    GROUP BY
        calendar_year,
        month_key,
        month_name,
        city_name,
        state_code
),
mv_result AS (
    SELECT
        calendar_year,
        month_key,
        month_name,
        city_name,
        state_code,
        ROUND(avg_temperature_f, 6) AS avg_temperature_f,
        ROUND(avg_apparent_temperature_f, 6) AS avg_apparent_temperature_f,
        ROUND(total_precipitation_in, 6) AS total_precipitation_in,
        ROUND(avg_cloud_cover_pct, 6) AS avg_cloud_cover_pct,
        observation_count
    FROM mv_weather_month_city
)
SELECT 'base_minus_mv' AS comparison_name, COUNT(*) AS differing_rows
FROM (SELECT * FROM base_result MINUS SELECT * FROM mv_result)
UNION ALL
SELECT 'mv_minus_base' AS comparison_name, COUNT(*) AS differing_rows
FROM (SELECT * FROM mv_result MINUS SELECT * FROM base_result);


-- ============================================================
-- Part 3B: Yearly Weather by Climate Category
-- Base-table query. Save/capture this output for the submission.
-- ============================================================
SELECT
    calendar_year,
    climate_category,
    climate_category_order,
    AVG(temperature_f) AS avg_temperature_f,
    AVG(apparent_temperature_f) AS avg_apparent_temperature_f,
    SUM(precipitation_in) AS total_precipitation_in,
    AVG(cloud_cover_pct) AS avg_cloud_cover_pct,
    COUNT(*) AS observation_count
FROM weather_analysis_base
GROUP BY
    calendar_year,
    climate_category,
    climate_category_order
ORDER BY
    calendar_year,
    climate_category_order;


-- Same query answered from the materialized view.
-- Save/capture this output too.
SELECT
    calendar_year,
    climate_category,
    climate_category_order,
    avg_temperature_f,
    avg_apparent_temperature_f,
    total_precipitation_in,
    avg_cloud_cover_pct,
    observation_count
FROM mv_weather_year_climate
ORDER BY
    calendar_year,
    climate_category_order;


-- Difference check. Both counts should be 0.
WITH base_result AS (
    SELECT
        calendar_year,
        climate_category,
        climate_category_order,
        ROUND(AVG(temperature_f), 6) AS avg_temperature_f,
        ROUND(AVG(apparent_temperature_f), 6) AS avg_apparent_temperature_f,
        ROUND(SUM(precipitation_in), 6) AS total_precipitation_in,
        ROUND(AVG(cloud_cover_pct), 6) AS avg_cloud_cover_pct,
        COUNT(*) AS observation_count
    FROM weather_analysis_base
    GROUP BY
        calendar_year,
        climate_category,
        climate_category_order
),
mv_result AS (
    SELECT
        calendar_year,
        climate_category,
        climate_category_order,
        ROUND(avg_temperature_f, 6) AS avg_temperature_f,
        ROUND(avg_apparent_temperature_f, 6) AS avg_apparent_temperature_f,
        ROUND(total_precipitation_in, 6) AS total_precipitation_in,
        ROUND(avg_cloud_cover_pct, 6) AS avg_cloud_cover_pct,
        observation_count
    FROM mv_weather_year_climate
)
SELECT 'base_minus_mv' AS comparison_name, COUNT(*) AS differing_rows
FROM (SELECT * FROM base_result MINUS SELECT * FROM mv_result)
UNION ALL
SELECT 'mv_minus_base' AS comparison_name, COUNT(*) AS differing_rows
FROM (SELECT * FROM mv_result MINUS SELECT * FROM base_result);


-- ============================================================
-- Part 4: Observation Over Time
-- Run this once, save/capture the output with the run timestamp,
-- then run it again at least 24 hours later.
-- ============================================================
SELECT
    CURRENT_TIMESTAMP() AS query_run_ts,
    calendar_year,
    month_key,
    month_name,
    city_name,
    state_code,
    avg_temperature_f,
    total_precipitation_in,
    avg_cloud_cover_pct,
    observation_count
FROM mv_weather_month_city
ORDER BY
    calendar_year,
    month_key,
    city_name;


-- ============================================================
-- Part 5: Query that cannot be answered by the monthly aggregate
-- This asks for daily detail, but MV_WEATHER_MONTH_CITY shrank time
-- to month and lost the individual FULL_DATE values.
-- ============================================================
SELECT
    full_date,
    city_name,
    state_code,
    AVG(temperature_f) AS avg_daily_temperature_f,
    SUM(precipitation_in) AS total_daily_precipitation_in,
    COUNT(*) AS daily_observation_count
FROM weather_analysis_base
GROUP BY
    full_date,
    city_name,
    state_code
ORDER BY
    full_date,
    city_name;


-- Second limitation example:
-- This cannot be answered by MV_WEATHER_YEAR_CLIMATE because city detail
-- was lost when the data was aggregated to year and climate category.
SELECT
    calendar_year,
    climate_category,
    city_name,
    AVG(temperature_f) AS avg_temperature_f,
    COUNT(*) AS observation_count
FROM weather_analysis_base
GROUP BY
    calendar_year,
    climate_category,
    city_name
ORDER BY
    calendar_year,
    climate_category,
    city_name;


-- ============================================================
-- Part 6 Optional: Query plan inspection
-- Run this if you want evidence for the optional EXPLAIN section.
-- ============================================================
EXPLAIN
SELECT
    calendar_year,
    month_key,
    month_name,
    city_name,
    state_code,
    AVG(temperature_f) AS avg_temperature_f,
    SUM(precipitation_in) AS total_precipitation_in,
    COUNT(*) AS observation_count
FROM weather_analysis_base
GROUP BY
    calendar_year,
    month_key,
    month_name,
    city_name,
    state_code;
