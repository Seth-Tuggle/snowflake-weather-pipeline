{{ config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key=['day_key', 'location_key']
) }}

with hourly_observations as (

    select
        day_key,
        location_key,
        temperature_2m
    from {{ ref('fct_weather_observation') }}

),

daily_rollup as (

    select
        day_key,
        location_key,
        min(temperature_2m) as min_temperature,
        max(temperature_2m) as max_temperature,
        sum(temperature_2m) as total_temperature,
        count(temperature_2m) as observation_count
    from hourly_observations
    group by
        day_key,
        location_key

)

select
    day_key,
    location_key,
    min_temperature,
    max_temperature,
    total_temperature,
    observation_count
from daily_rollup
