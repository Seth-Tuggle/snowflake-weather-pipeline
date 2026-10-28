-- HW06 setup for your current Snowflake schema.
-- Run these blocks in Snowflake using WEATHER_DB.RAW.
-- These statements replace only the HW06 analysis objects.

USE DATABASE WEATHER_DB;
USE SCHEMA RAW;
USE WAREHOUSE COMPUTE_WH;


-- Optional check: if WEATHER_ANALYSIS_BASE already exists, you can skip
-- the DT_WEATHER_ANALYSIS_BASE and WEATHER_ANALYSIS_BASE setup blocks.
SHOW TABLES LIKE 'WEATHER_ANALYSIS_BASE' IN SCHEMA WEATHER_DB.RAW;
SHOW DYNAMIC TABLES LIKE 'DT_WEATHER_ANALYSIS_BASE' IN SCHEMA WEATHER_DB.RAW;


-- Setup block 1: derived Snowflake-maintained analysis base.
-- Column names are adapted from the current dbt models:
--   FCT_WEATHER_OBSERVATION.temperature_2m -> temperature_f
--   FCT_WEATHER_OBSERVATION.apparent_temperature -> apparent_temperature_f
--   FCT_WEATHER_OBSERVATION.precipitation -> precipitation_in
--   FCT_WEATHER_OBSERVATION.cloud_cover -> cloud_cover_pct
CREATE OR REPLACE DYNAMIC TABLE dt_weather_analysis_base
  TARGET_LAG = '1 hour'
  WAREHOUSE = COMPUTE_WH
AS
SELECT
    MD5(
        CAST(f.location_key AS VARCHAR)
        || '|'
        || CAST(f.day_key AS VARCHAR)
        || '|'
        || CAST(f.minute_key AS VARCHAR)
    ) AS weather_observation_key,
    f.day_key,
    f.minute_key,
    f.location_key,

    d.full_date,
    d.year_number AS calendar_year,
    d.month_number AS month_key,
    d.month_name,
    d.season_name AS season,

    m.minute_key AS minute_of_day,
    m.hour_24,
    m.day_period AS time_of_day_bucket,

    l.city_name,
    l.state_name AS state_code,
    l.latitude,
    l.longitude,
    l.elevation_m AS elevation,
    l.climate_category,
    l.climate_category_order,

    f.observation_timestamp AS observation_ts,
    f.temperature_2m AS temperature_f,
    f.apparent_temperature AS apparent_temperature_f,
    f.precipitation AS precipitation_in,
    f.cloud_cover AS cloud_cover_pct,
    f.relative_humidity_2m,
    f.wind_speed_10m,
    f.weather_code
FROM WEATHER_DB.RAW.fct_weather_observation f
JOIN WEATHER_DB.RAW.dim_day d
  ON f.day_key = d.day_key
JOIN WEATHER_DB.RAW.dim_minute m
  ON f.minute_key = m.minute_key
JOIN WEATHER_DB.RAW.dim_location l
  ON f.location_key = l.location_key;


-- Setup block 2: helper table for materialized views.
-- Snowflake materialized views cannot be built directly from a dynamic table,
-- so this regular table is the base table for the two aggregate MVs.
CREATE OR REPLACE TABLE weather_analysis_base AS
SELECT
    weather_observation_key,
    day_key,
    minute_key,
    location_key,
    full_date,
    calendar_year,
    month_key,
    month_name,
    season,
    minute_of_day,
    hour_24,
    time_of_day_bucket,
    city_name,
    state_code,
    latitude,
    longitude,
    elevation,
    climate_category,
    climate_category_order,
    observation_ts,
    temperature_f,
    apparent_temperature_f,
    precipitation_in,
    cloud_cover_pct,
    relative_humidity_2m,
    wind_speed_10m,
    weather_code
FROM dt_weather_analysis_base;


-- Aggregate 1: one row per year/month/city.
-- Calendar year is included so January 2026 and January 2027 do not collapse
-- into the same row if your data later spans multiple years.
CREATE OR REPLACE MATERIALIZED VIEW mv_weather_month_city
AS
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
    state_code;


-- Aggregate 2: one row per year/climate category.
CREATE OR REPLACE MATERIALIZED VIEW mv_weather_year_climate
AS
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
    climate_category_order;


-- Verification block.
SHOW DYNAMIC TABLES LIKE 'DT_WEATHER_ANALYSIS_BASE' IN SCHEMA WEATHER_DB.RAW;
SHOW TABLES LIKE 'WEATHER_ANALYSIS_BASE' IN SCHEMA WEATHER_DB.RAW;
SHOW MATERIALIZED VIEWS LIKE 'MV_WEATHER%' IN SCHEMA WEATHER_DB.RAW;

SELECT COUNT(*) AS weather_analysis_base_rows
FROM weather_analysis_base;

SELECT *
FROM mv_weather_month_city
ORDER BY calendar_year, month_key, city_name;

SELECT *
FROM mv_weather_year_climate
ORDER BY calendar_year, climate_category_order;
