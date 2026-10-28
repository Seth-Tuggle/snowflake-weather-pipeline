select
    day_key,
    location_key,
    minute_key,
    count(*) as row_count
from {{ ref('weather_analysis_base') }}
group by
    day_key,
    location_key,
    minute_key
having count(*) > 1
