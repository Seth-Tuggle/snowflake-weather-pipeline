{{ config(materialized='table') }}

with source_data as (

    select
        city_name,
        state_name,
        latitude,
        longitude,
        time_utc,
        temperature_2m,
        apparent_temperature,
        relative_humidity_2m,
        precipitation,
        wind_speed_10m,
        cloud_cover,
        weather_code,
        load_timestamp
    from {{ source('weather_raw', 'stg_weather_hourly_raw') }}

),

typed as (

    select
        cast(city_name as varchar) as city_name,
        cast(state_name as varchar) as state_name,
        cast(latitude as float) as latitude,
        cast(longitude as float) as longitude,
        cast(time_utc as timestamp_ntz) as observation_timestamp,
        cast(temperature_2m as float) as temperature_2m,
        cast(apparent_temperature as float) as apparent_temperature,
        cast(relative_humidity_2m as float) as relative_humidity_2m,
        cast(precipitation as float) as precipitation,
        cast(wind_speed_10m as float) as wind_speed_10m,
        cast(cloud_cover as float) as cloud_cover,
        cast(weather_code as integer) as weather_code,
        cast(load_timestamp as timestamp_ntz) as load_timestamp
    from source_data

),

deduped as (

    select
        city_name,
        state_name,
        latitude,
        longitude,
        observation_timestamp,
        temperature_2m,
        apparent_temperature,
        relative_humidity_2m,
        precipitation,
        wind_speed_10m,
        cloud_cover,
        weather_code,
        load_timestamp
    from typed
    qualify row_number() over (
        partition by city_name, state_name, observation_timestamp
        order by load_timestamp desc
    ) = 1

),

derived as (

    select
        city_name,
        state_name,
        latitude,
        longitude,
        observation_timestamp,
        cast(to_char(observation_timestamp, 'YYYYMMDD') as integer) as day_key,
        cast(
            extract(hour from observation_timestamp) * 60
            + extract(minute from observation_timestamp)
            as integer
        ) as minute_key,
        temperature_2m,
        apparent_temperature,
        relative_humidity_2m,
        precipitation,
        wind_speed_10m,
        cloud_cover,
        weather_code,
        load_timestamp
    from deduped

)

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
from derived

