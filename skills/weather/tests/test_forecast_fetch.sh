#!/bin/bash
# test_forecast_fetch.sh — verify wttr.in + Open-Meteo fallback from inside the container.
# Usage: ./test_forecast_fetch.sh "Los Altos, CA"
#        ./test_forecast_fetch.sh "London"
set -euo pipefail

LOCATION="${1:-}"
if [[ -z "$LOCATION" ]]; then
  echo "Usage: $(basename "$0") <location>" >&2
  echo "  e.g. $(basename "$0") \"Los Altos, CA\"" >&2
  exit 1
fi

# Resolve docker-compose.yml location (two levels up from this script)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_DIR="$(cd "$SCRIPT_DIR/../../../../openclaw" && pwd)"

run() {
  (cd "$COMPOSE_DIR" && docker compose exec -u node openclaw-gateway bash -c "$1")
}

echo "==> Testing weather fetch for: $LOCATION"
echo ""

# Encode location for URL (spaces → %20)
ENCODED="${LOCATION// /%20}"

echo "--- wttr.in (with retries) ---"
RESULT=$(run "curl -s --retry 3 --retry-delay 2 --max-time 10 'wttr.in/${ENCODED}?format=3&u'" 2>/dev/null || true)
if [[ -n "$RESULT" ]]; then
  echo "PASS: $RESULT"
else
  echo "WARN: wttr.in returned empty — testing Open-Meteo fallback..."
fi

echo ""
echo "--- Open-Meteo fallback ---"
# Geocoding API works best with just the city name (strip state/country suffix)
CITY_ONLY="${LOCATION%%,*}"
CITY_ENCODED="${CITY_ONLY// /%20}"
run "
  GEO=\$(curl -s 'https://geocoding-api.open-meteo.com/v1/search?name=${CITY_ENCODED}&count=1')
  LAT=\$(echo \"\$GEO\" | jq -r '.results[0].latitude')
  LON=\$(echo \"\$GEO\" | jq -r '.results[0].longitude')
  NAME=\$(echo \"\$GEO\" | jq -r '.results[0].name')
  COUNTRY=\$(echo \"\$GEO\" | jq -r '.results[0].country')
  echo \"Resolved: \$NAME, \$COUNTRY (lat=\$LAT, lon=\$LON)\"
  FORECAST=\$(curl -s \"https://api.open-meteo.com/v1/forecast?latitude=\$LAT&longitude=\$LON&current_weather=true&daily=temperature_2m_max,temperature_2m_min,precipitation_sum,precipitation_probability_max&timezone=auto&forecast_days=3&temperature_unit=fahrenheit&windspeed_unit=mph\")
  TEMP=\$(echo \"\$FORECAST\" | jq -r '.current_weather.temperature')
  WIND=\$(echo \"\$FORECAST\" | jq -r '.current_weather.windspeed')
  echo \"Current: \${TEMP}°F, wind \${WIND} mph\"
  echo \"Forecast (3-day max/min °F):\"
  echo \"\$FORECAST\" | jq -r '.daily | [.time, .temperature_2m_max, .temperature_2m_min] | transpose[] | \"\(.[0]): max \(.[1])°F  min \(.[2])°F\"'
"
echo ""
echo "==> Done"
