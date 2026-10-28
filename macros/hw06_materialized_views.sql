{% macro hw06_relation(base_relation, identifier) %}
    {{ return(api.Relation.create(
        database=base_relation.database,
        schema=base_relation.schema,
        identifier=identifier
    )) }}
{% endmacro %}


{% macro create_mv_weather_month_city(base_relation) %}
    {% set mv_relation = hw06_relation(base_relation, 'mv_weather_month_city') %}

    create or replace materialized view {{ mv_relation }} as
    select
        month_key,
        month_name,
        calendar_year,
        city_name,
        state_code,
        avg(temperature_f) as avg_temperature_f,
        avg(apparent_temperature_f) as avg_apparent_temperature_f,
        sum(precipitation_in) as total_precipitation_in,
        avg(cloud_cover_pct) as avg_cloud_cover_pct,
        count(*) as observation_count
    from {{ base_relation }}
    group by
        month_key,
        month_name,
        calendar_year,
        city_name,
        state_code
{% endmacro %}


{% macro create_mv_weather_year_climate(base_relation) %}
    {% set mv_relation = hw06_relation(base_relation, 'mv_weather_year_climate') %}

    create or replace materialized view {{ mv_relation }} as
    select
        calendar_year,
        climate_category,
        climate_category_order,
        avg(temperature_f) as avg_temperature_f,
        avg(apparent_temperature_f) as avg_apparent_temperature_f,
        sum(precipitation_in) as total_precipitation_in,
        avg(cloud_cover_pct) as avg_cloud_cover_pct,
        count(*) as observation_count
    from {{ base_relation }}
    group by
        calendar_year,
        climate_category,
        climate_category_order
{% endmacro %}
