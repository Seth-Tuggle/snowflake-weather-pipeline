

#!/usr/bin/env python3
"""
End-to-end straw (no dbt):
Open-Meteo API -> Snowflake STG_WEATHER_HOURLY_RAW table -> downstream models read raw

Key-pair authentication:
- Uses private_key_file (+ optional private_key_file_pwd) for Snowflake connector.

Idempotent load:
- Re-pulls a rolling window (PAST_DAYS) and MERGEs on (city_name, state_name, time_utc)
"""

from __future__ import annotations

import os
import time
import logging
from dataclasses import dataclass
from datetime import datetime, timezone
from typing import Dict, List, Tuple, Any, Optional

import requests
import snowflake.connector


# -----------------------------
# Configuration
# -----------------------------
@dataclass(frozen=True)
class Station:
    name: str
    latitude: float
    longitude: float


STATIONS: List[Station] = [
    Station("Radford, VA", 37.1318, -80.5764),
    Station("Phoenix, AZ", 33.4484, -112.0740),
    Station("Chicago, IL", 41.8781, -87.6298),
    Station("Miami, FL", 25.7617, -80.1918),
    Station("Seattle, WA", 47.6062, -122.3321),
]

HOURLY_VARS = [
    "temperature_2m",
    "apparent_temperature",
    "precipitation",
    "wind_speed_10m",
    "relative_humidity_2m",
    "cloud_cover",
    "weather_code",
]

OPEN_METEO_URL = "https://api.open-meteo.com/v1/forecast"
TARGET_TABLE = "STG_WEATHER_HOURLY_RAW"
STAGE_TABLE = f"{TARGET_TABLE}_STAGE"


def get_env(name: str, default: Optional[str] = None, required: bool = False) -> str:
    val = os.getenv(name, default)
    if required and (val is None or val.strip() == ""):
        raise RuntimeError(f"Missing required environment variable: {name}")
    return val  # type: ignore


def setup_logging() -> None:
    level = get_env("LOG_LEVEL", "INFO").upper()
    logging.basicConfig(
        level=level,
        format="%(asctime)sZ %(levelname)s %(message)s",
        datefmt="%Y-%m-%dT%H:%M:%S",
    )


# -----------------------------
# Open-Meteo fetch
# -----------------------------
def fetch_hourly(station: Station, past_days: int, timeout_s: int, retries: int) -> Dict[str, Any]:
    params = {
        "latitude": station.latitude,
        "longitude": station.longitude,
        "hourly": ",".join(HOURLY_VARS),
        "past_days": past_days,
        "timezone": "UTC",  # keep it simple & consistent
    }

    last_err: Optional[Exception] = None
    for attempt in range(1, retries + 1):
        try:
            r = requests.get(OPEN_METEO_URL, params=params, timeout=timeout_s)
            r.raise_for_status()
            return r.json()
        except Exception as e:
            last_err = e
            wait = min(2 ** attempt, 20)
            logging.warning(
                "Fetch failed for %s (attempt %d/%d): %s. Retrying in %ds",
                station.name, attempt, retries, str(e), wait
            )
            time.sleep(wait)
    raise RuntimeError(f"Failed to fetch Open-Meteo data for {station.name}: {last_err}")


def normalize_rows(station: Station, payload: Dict[str, Any]) -> List[Tuple]:
    """
    Converts Open-Meteo hourly arrays into row tuples for Snowflake.
    Stores time_utc as TIMESTAMP_NTZ (UTC by convention).
    """
    hourly = payload.get("hourly", {})
    times = hourly.get("time", [])

    temp = hourly.get("temperature_2m", [])
    apparent_temp = hourly.get("apparent_temperature", [])
    precip = hourly.get("precipitation", [])
    wind = hourly.get("wind_speed_10m", [])
    rh = hourly.get("relative_humidity_2m", [])
    cloud_cover = hourly.get("cloud_cover", [])
    weather_code = hourly.get("weather_code", [])
    city_name, state_name = [part.strip() for part in station.name.split(",", 1)]

    ingested_at = datetime.now(timezone.utc).replace(tzinfo=None)

    rows: List[Tuple] = []
    for i, t in enumerate(times):
        # e.g. "2026-03-20T14:00" (timezone=UTC)
        dt_utc = datetime.fromisoformat(t).replace(tzinfo=timezone.utc).replace(tzinfo=None)

        rows.append((
            city_name,
            state_name,
            station.latitude,
            station.longitude,
            dt_utc,
            float(temp[i]) if i < len(temp) and temp[i] is not None else None,
            float(apparent_temp[i]) if i < len(apparent_temp) and apparent_temp[i] is not None else None,
            float(rh[i]) if i < len(rh) and rh[i] is not None else None,
            float(precip[i]) if i < len(precip) and precip[i] is not None else None,
            float(wind[i]) if i < len(wind) and wind[i] is not None else None,
            float(cloud_cover[i]) if i < len(cloud_cover) and cloud_cover[i] is not None else None,
            int(weather_code[i]) if i < len(weather_code) and weather_code[i] is not None else None,
            ingested_at,
        ))
    return rows


# -----------------------------
# Snowflake load (MERGE for idempotency)
# -----------------------------
CREATE_STAGE_TABLE_SQL = f"""
create or replace temporary table {STAGE_TABLE} like {TARGET_TABLE};
"""

INSERT_STAGE_SQL = f"""
insert into {STAGE_TABLE} (
  city_name, state_name, latitude, longitude,
  time_utc, temperature_2m, apparent_temperature, relative_humidity_2m,
  precipitation, wind_speed_10m, cloud_cover, weather_code, load_timestamp
) values (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s);
"""

MERGE_SQL = f"""
merge into {TARGET_TABLE} t
using {STAGE_TABLE} s
  on t.city_name = s.city_name
 and t.state_name = s.state_name
 and t.time_utc = s.time_utc
when matched then update set
    t.latitude = s.latitude,
    t.longitude = s.longitude,
    t.temperature_2m = s.temperature_2m,
    t.apparent_temperature = s.apparent_temperature,
    t.relative_humidity_2m = s.relative_humidity_2m,
    t.precipitation = s.precipitation,
    t.wind_speed_10m = s.wind_speed_10m,
    t.cloud_cover = s.cloud_cover,
    t.weather_code = s.weather_code,
    t.load_timestamp = s.load_timestamp
when not matched then insert (
    city_name, state_name, latitude, longitude,
    time_utc, temperature_2m, apparent_temperature, relative_humidity_2m,
    precipitation, wind_speed_10m, cloud_cover, weather_code, load_timestamp
) values (
    s.city_name, s.state_name, s.latitude, s.longitude,
    s.time_utc, s.temperature_2m, s.apparent_temperature, s.relative_humidity_2m,
    s.precipitation, s.wind_speed_10m, s.cloud_cover, s.weather_code,
    s.load_timestamp
);
"""


def snowflake_connect():
    """
    Key-pair auth via Snowflake Python connector:
    - private_key_file = path to .p8
    """
    private_key_file_pwd = os.getenv("SNOWFLAKE_PRIVATE_KEY_PASSPHRASE") or None

    private_key_path = get_env("SNOWFLAKE_PRIVATE_KEY_PATH", required=True)
    # Prefer an explicit Snowflake env var name, but allow common aliases.
    private_key_pwd = (
        os.getenv("SNOWFLAKE_PRIVATE_KEY_PASSPHRASE")
        or os.getenv("SNOWFLAKE_PRIVATE_KEY_PASSWORD")
        or os.getenv("PRIVATE_KEY_PASSPHRASE")
    )  # optional

    connect_kwargs = dict(
        account=get_env("SNOWFLAKE_ACCOUNT", required=True),
        user=get_env("SNOWFLAKE_USER", required=True),
        warehouse=get_env("SNOWFLAKE_WAREHOUSE", required=True),
        database=get_env("SNOWFLAKE_DATABASE", required=True),
        schema=get_env("SNOWFLAKE_SCHEMA", "RAW"),
        role=os.getenv("SNOWFLAKE_ROLE"),
        private_key_file=private_key_path,
    )

    if private_key_pwd:
        connect_kwargs["private_key_file_pwd"] = private_key_pwd

    return snowflake.connector.connect(**connect_kwargs)


def load_rows(conn, rows: List[Tuple]) -> int:
    if not rows:
        return 0

    with conn.cursor() as cur:
        cur.execute(CREATE_STAGE_TABLE_SQL)
        cur.executemany(INSERT_STAGE_SQL, rows)
        cur.execute(MERGE_SQL)
        return len(rows)


def main() -> int:
    setup_logging()

    past_days = int(get_env("PAST_DAYS", "2"))
    timeout_s = int(get_env("HTTP_TIMEOUT_SECONDS", "20"))
    retries = int(get_env("HTTP_RETRIES", "3"))

    logging.info("Starting ingestion. stations=%d past_days=%d", len(STATIONS), past_days)

    all_rows: List[Tuple] = []
    for st in STATIONS:
        payload = fetch_hourly(st, past_days=past_days, timeout_s=timeout_s, retries=retries)
        rows = normalize_rows(st, payload)
        logging.info("Fetched %d hourly rows for %s", len(rows), st.name)
        all_rows.extend(rows)

    logging.info("Total rows to stage: %d", len(all_rows))

    conn = snowflake_connect()
    try:
        staged = load_rows(conn, all_rows)
        conn.commit()
        logging.info("Load complete. staged_rows=%d", staged)
    finally:
        conn.close()

    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as e:
        logging.exception("Ingestion failed: %s", str(e))
        raise
