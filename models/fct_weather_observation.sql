{{ config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key=['location_key', 'day_key', 'minute_key']
) }}

with hourly as (

    select
        city_name,
        state_name,
        latitude,
        longitude,
        observation_timestamp,
        day_key,
        minute_key,
        temperature_2m,
        apparent_temperature,
        relative_humidity_2m,
        precipitation,
        wind_speed_10m,
        cloud_cover,
        weather_code,
        load_timestamp
    from {{ ref('stg_weather_hourly') }}

),

dim_location as (

    select
        location_key,
        city_name,
        state_name
    from {{ source('weather_dw', 'dim_location') }}

),

dim_day as (

    select
        day_key
    from {{ source('weather_dw', 'dim_day') }}

),

dim_minute as (

    select
        minute_key
    from {{ source('weather_dw', 'dim_minute') }}

),

joined as (

    select
        l.location_key,
        d.day_key,
        m.minute_key,
        h.observation_timestamp,
        h.temperature_2m,
        h.apparent_temperature,
        h.relative_humidity_2m,
        h.precipitation,
        h.wind_speed_10m,
        h.cloud_cover,
        h.weather_code,
        h.load_timestamp
    from hourly h
    inner join dim_location l
        on h.city_name = l.city_name
       and h.state_name = l.state_name
    inner join dim_day d
        on h.day_key = d.day_key
    inner join dim_minute m
        on h.minute_key = m.minute_key

)

select
    location_key,
    day_key,
    minute_key,
    observation_timestamp,
    temperature_2m,
    apparent_temperature,
    relative_humidity_2m,
    precipitation,
    wind_speed_10m,
    cloud_cover,
    weather_code,
    load_timestamp
from joined

