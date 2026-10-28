#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
: "${SNOWFLAKE_ACCOUNT:?Set SNOWFLAKE_ACCOUNT}"
: "${SNOWFLAKE_USER:?Set SNOWFLAKE_USER}"
: "${SNOWFLAKE_PRIVATE_KEY_PATH:?Set SNOWFLAKE_PRIVATE_KEY_PATH}"
python weather_ingest.py
dbt run --select stg_weather_hourly+
# Staging cleanup is deliberately manual: python cleanup_staging.py
