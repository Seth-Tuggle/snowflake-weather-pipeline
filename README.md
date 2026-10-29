# Snowflake Weather Pipeline

A weather data engineering project from CS542: Open-Meteo observations flow
through Python ingestion into Snowflake and dbt staging, fact, snapshot, and
analytical models.

## Included work

- Rolling-window, idempotent MERGE ingestion with key-pair authentication.
- Observation facts, daily snapshot models, analytical marts, and aggregate SQL.
- Grain validation queries, YAML model definitions, and dimension generators.

## Setup

1. Create a Python environment and install `requirements.txt`.
2. Supply your own Snowflake account, role, warehouse, and key pair. The examples
   use `WEATHER_DB`; they do not refer to the former school database.
3. Export the variables documented in `.env.example`. The ingest script reads
   process environment variables; it does not automatically load that file.
4. Configure a local dbt `profiles.yml` using `profiles.example.yml` as a guide.
5. Create/populate the raw and dimension tables referenced by `models/sources.yml`.
   The `dimensions/` scripts and sample location CSV support this step. The
   recovered aggregate SQL assumes existing source/fact tables; it is not a
   complete empty-account bootstrap migration.
6. Run `python weather_ingest.py`, then `dbt run --select stg_weather_hourly+`.
   Run relevant validation with `dbt test` after preparing the database.

The shell runner requires an already configured environment. Staging cleanup is
manual to avoid silently removing data. No cloud commands were run during recovery.
