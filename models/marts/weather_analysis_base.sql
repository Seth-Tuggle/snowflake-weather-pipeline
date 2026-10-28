{{ config(
    materialized='table',
    schema='MART',
    post_hook=[
        "{{ create_mv_weather_month_city(this) }}",
        "{{ create_mv_weather_year_climate(this) }}"
    ]
) }}

select
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
    weather_code
from {{ ref('dt_weather_analysis_base') }}
