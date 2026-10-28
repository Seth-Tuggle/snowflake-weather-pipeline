-- Row count check: transaction fact versus daily snapshot.
select
    'fct_weather_observation' as table_name,
    count(*) as row_count
from {{ ref('fct_weather_observation') }}

union all

select
    'fct_weather_daily_snapshot' as table_name,
    count(*) as row_count
from {{ ref('fct_weather_daily_snapshot') }};


-- Snapshot should be close to distinct city/day combinations.
select
    count(distinct location_key) as city_count,
    count(distinct day_key) as day_count,
    count(*) as snapshot_row_count,
    count(distinct location_key) * count(distinct day_key) as expected_city_day_rows
from {{ ref('fct_weather_daily_snapshot') }};


-- Additive validation: snapshot totals must match transaction totals.
select
    transaction_totals.total_temperature as transaction_total_temperature,
    snapshot_totals.total_temperature as snapshot_total_temperature,
    transaction_totals.observation_count as transaction_observation_count,
    snapshot_totals.observation_count as snapshot_observation_count
from (
    select
        sum(temperature_2m) as total_temperature,
        count(temperature_2m) as observation_count
    from {{ ref('fct_weather_observation') }}
) as transaction_totals
cross join (
    select
        sum(total_temperature) as total_temperature,
        sum(observation_count) as observation_count
    from {{ ref('fct_weather_daily_snapshot') }}
) as snapshot_totals;


-- Grain check: there should be no duplicate day/location rows.
select
    day_key,
    location_key,
    count(*) as row_count
from {{ ref('fct_weather_daily_snapshot') }}
group by
    day_key,
    location_key
having count(*) > 1;
