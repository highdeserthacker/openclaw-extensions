---
name: weather
description: This skill should be used when the user asks for current weather, weather forecasts, temperature, for any location. For example, if the user asks for "weather", or "what's the weather forecast".
metadata: {"openclaw":{"emoji": "🌤️", "requires": {"bins": ["curl", "jq"]}}}
---
# Weather Skill (Custom Override)

Get the weather using wttr.in or Open-Meteo.

## Usage

Get current weather or 3-day forecast for a city or GPS coords (lat,lon).

## Examples

```bash
# Get weather for San Francisco (°F)
curl -s "wttr.in/San%20Francisco?u&format=3"

# Get weather for London (°F)
curl -s "wttr.in/London?u&format=3"

# Latitude/Longitude (°F)
curl -s "wttr.in/37.7749,-122.4194?u&format=3"
```

## Reliability & Fallback

wttr.in is a free service that is intermittently unavailable. **Always** use
retries, and fall back to Open-Meteo when wttr.in returns an empty response.

### Always use retries for wttr.in

```bash
curl -s --retry 3 --retry-delay 2 --max-time 10 "wttr.in/CITY?u&format=3"
```

### Full fallback pattern (preferred)

```bash
RESULT=$(curl -s --retry 3 --retry-delay 2 --max-time 10 "wttr.in/CITY?u&format=3")
if [ -z "$RESULT" ]; then
  echo "wttr.in unavailable — falling back to Open-Meteo"
  GEO=$(curl -s "https://geocoding-api.open-meteo.com/v1/search?name=CITY&count=1")
  LAT=$(echo "$GEO" | jq -r '.results[0].latitude')
  LON=$(echo "$GEO" | jq -r '.results[0].longitude')
  curl -s "https://api.open-meteo.com/v1/forecast?latitude=$LAT&longitude=$LON&current_weather=true&daily=temperature_2m_max,temperature_2m_min,precipitation_sum,precipitation_probability_max,windspeed_10m_max&timezone=auto&forecast_days=3&temperature_unit=fahrenheit&windspeed_unit=mph"
fi
```

### Open-Meteo standalone (always available, no API key, use as direct fallback)

```bash
# Step 1 — geocode city to lat/lon
GEO=$(curl -s "https://geocoding-api.open-meteo.com/v1/search?name=CITY&count=1")
LAT=$(echo "$GEO" | jq -r '.results[0].latitude')
LON=$(echo "$GEO" | jq -r '.results[0].longitude')

# Step 2 — current conditions + 3-day forecast (°F, mph)
curl -s "https://api.open-meteo.com/v1/forecast?latitude=$LAT&longitude=$LON&current_weather=true&daily=temperature_2m_max,temperature_2m_min,precipitation_sum,precipitation_probability_max,windspeed_10m_max&timezone=auto&forecast_days=3&temperature_unit=fahrenheit&windspeed_unit=mph"
```

Response fields: `current_weather.temperature` (°F), `current_weather.windspeed` (mph),
`daily.temperature_2m_max/min`, `daily.precipitation_sum`, `daily.precipitation_probability_max`.
