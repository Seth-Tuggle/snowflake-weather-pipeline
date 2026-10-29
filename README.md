# Snowflake Weather Pipeline

## Historical coursework

I'm preserving this older CS542 project as a description of my coursework and a
home for the main code. It was built around a configured class environment, not
as an application for an individual device. I'm not maintaining a standalone
setup; service access, dependencies, and APIs may now be outdated or deprecated.

## About the project

My project follows weather observations from Open-Meteo through Python ingestion,
Snowflake storage, and dbt models. I use it to explore how hourly data can become
observation facts, daily snapshots, and analytical tables.

- The Python ingestion scripts normalize observations and use rolling-window
  MERGE loads to avoid duplicate records.
- `models/` contains dbt staging, fact, snapshot, and analytical models.
- `dimensions/`, `analyses/`, `macros/`, and `tests/` hold supporting generators,
  aggregate SQL, and validation queries.

## Original environment and limitations

The code assumes a Snowflake account with the class database, raw tables, and
populated dimensions already configured, along with Python, dbt, and key-pair
authentication. Example environment/profile files describe the expected settings;
private account information and credentials aren't included.

The repository doesn't contain a complete bootstrap for an empty account. Some
scripts come from different stages of the class work and use different raw-table
layouts. The shell runner also assumes a configured environment, and staging
cleanup remains a separate manual step.

## Ownership

For details about my contributions and project attribution, see [CREDITS.md](CREDITS.md).
