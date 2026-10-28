#!/usr/bin/env python3

from weather_ingest import get_env, snowflake_connect


def main() -> int:
    database = get_env("SNOWFLAKE_DATABASE", required=True)
    raw_schema = get_env("RAW_SCHEMA", get_env("SNOWFLAKE_SCHEMA", "RAW"))
    dbt_schema = get_env("DBT_SCHEMA", raw_schema)

    raw_table = f"{database}.{raw_schema}.STG_WEATHER_HOURLY_RAW"
    clean_table = f"{database}.{dbt_schema}.STG_WEATHER_HOURLY"

    conn = snowflake_connect()
    try:
        with conn.cursor() as cur:
            cur.execute(f"TRUNCATE TABLE {raw_table}")
            cur.execute(f"TRUNCATE TABLE {clean_table}")
        conn.commit()
        print(f"Truncated {raw_table}")
        print(f"Truncated {clean_table}")
    finally:
        conn.close()

    return 0


if __name__ == "__main__":
    raise SystemExit(main())

