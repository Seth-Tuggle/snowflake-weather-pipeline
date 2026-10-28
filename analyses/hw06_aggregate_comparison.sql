{% set base_relation = ref('weather_analysis_base') %}
{% set mv_month_city = api.Relation.create(
    database=base_relation.database,
    schema=base_relation.schema,
    identifier='mv_weather_month_city'
) %}

select
    month_key,
    city_name,
    avg(temperature_f) as avg_temperature_f,
    sum(precipitation_in) as total_precipitation_in
from {{ base_relation }}
group by
    month_key,
    city_name
order by
    month_key,
    city_name;

select
    month_key,
    city_name,
    avg_temperature_f,
    total_precipitation_in
from {{ mv_month_city }}
order by
    month_key,
    city_name;

explain
select
    month_key,
    city_name,
    avg(temperature_f) as avg_temperature_f,
    sum(precipitation_in) as total_precipitation_in
from {{ base_relation }}
group by
    month_key,
    city_name;
