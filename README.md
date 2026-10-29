# Snowflake Weather Pipeline

My CS542 project follows weather observations from Open-Meteo through Python
ingestion, Snowflake storage, and dbt models. I use it to explore how hourly data
can become observation facts, daily snapshots, and analytical tables.

## What's included

- Rolling-window ingestion that uses MERGE to avoid duplicate observations.
- Key-pair authentication, dbt staging and fact models, and aggregate SQL.
- Dimension generators, model definitions, and queries for checking table grain.

## Setup

1. Create a Python environment and install `requirements.txt`.
2. Set up your own Snowflake account, role, warehouse, and key pair. My example
   configuration uses `WEATHER_DB`.
3. Export the variables listed in `.env.example`. The ingestion script reads
   process environment variables; it doesn't load that file automatically.
4. Configure your local dbt `profiles.yml` using `profiles.example.yml` as a guide.
5. Create and populate the raw and dimension tables in `models/sources.yml`.
   The scripts and sample location CSV in `dimensions/` can help with this step.
6. Run `python weather_ingest.py`, then `dbt run --select stg_weather_hourly+`.
   Once the database is ready, use `dbt test` to run the model checks.

## Things to know

The aggregate SQL assumes that source and fact tables already exist. I haven't
included a complete setup migration for an empty Snowflake account, so review the
table requirements before running it.

The shell runner also needs a configured environment. I keep staging cleanup as
a separate manual step so running the pipeline doesn't silently remove data.

## Ownership

For details about my contributions and project attribution, see [CREDITS.md](CREDITS.md).
