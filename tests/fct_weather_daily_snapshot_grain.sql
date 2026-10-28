select
    day_key,
    location_key,
    count(*) as row_count
from {{ ref('fct_weather_daily_snapshot') }}
group by
    day_key,
    location_key
having count(*) > 1
