{{ config(
    materialized='dynamic_table',
    schema='MART',
    target_lag='1 hour',
    snowflake_warehouse=env_var('SNOWFLAKE_WAREHOUSE', 'COMPUTE_WH'),
    on_configuration_change='apply'
) }}

with observation_fact as (

    select
        md5(
            cast(location_key as varchar)
            || '|'
            || cast(day_key as varchar)
            || '|'
            || cast(minute_key as varchar)
        ) as weather_observation_key,
        location_key,
        day_key,
        minute_key,
        observation_timestamp as observation_ts,
        temperature_2m as temperature_f,
        apparent_temperature as apparent_temperature_f,
        precipitation as precipitation_in,
        cloud_cover as cloud_cover_pct,
        weather_code
    from {{ ref('fct_weather_observation') }}

),

dim_day as (

    select
        day_key,
        full_date,
        year_number as calendar_year,
        month_number as month_key,
        month_name,
        season_name as season
    from {{ source('weather_dw', 'dim_day') }}

),

dim_minute as (

    select
        minute_key,
        minute_key as minute_of_day,
        hour_24,
        day_period as time_of_day_bucket
    from {{ source('weather_dw', 'dim_minute') }}

),

dim_location as (

    select
        location_key,
        city_name,
        state_name as state_code,
        latitude,
        longitude,
        elevation_m as elevation,
        climate_category,
        climate_category_order
    from {{ source('weather_dw', 'dim_location') }}

)

select
    f.weather_observation_key,
    f.day_key,
    f.minute_key,
    f.location_key,
    d.full_date,
    d.calendar_year,
    d.month_key,
    d.month_name,
    d.season,
    m.minute_of_day,
    m.hour_24,
    m.time_of_day_bucket,
    l.city_name,
    l.state_code,
    l.latitude,
    l.longitude,
    l.elevation,
    l.climate_category,
    l.climate_category_order,
    f.observation_ts,
    f.temperature_f,
    f.apparent_temperature_f,
    f.precipitation_in,
    f.cloud_cover_pct,
    f.weather_code
from observation_fact f
inner join dim_day d
    on f.day_key = d.day_key
inner join dim_minute m
    on f.minute_key = m.minute_key
inner join dim_location l
    on f.location_key = l.location_key
