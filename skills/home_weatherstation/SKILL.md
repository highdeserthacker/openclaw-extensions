---
name: home_weatherstation
description: This skill should be used when the user asks for weather at home or if the user location is at home and asking for weather (and not specifying some other location). The user may specify a particular attribute such as temperature, humidity, wind speed, wind direction, rain.
metadata: {"openclaw":{"requires":{"bins":["curl"],"env":["HA_TOKEN"]}}}
---
# Home Weather Station

Fetch all current readings:
```bash
curl -s http://10.0.0.22:8123/api/states/sensor.weather_station \
  -H "Authorization: Bearer ${HA_TOKEN}" \
  | python3 -c '''
import json, sys
d = json.load(sys.stdin)
state_data = json.loads(d['state'])
temperature = state_data.get('Temperature')
humidity = state_data.get('Humidity')
wind_speed = state_data.get('WindSpeed')
wind_dir = state_data.get('WindDir')
wind_speed_peak = state_data.get('WindSpeedPeakMph')
temp_peak_24hr = state_data.get('TemperaturePeak24Hr')
raining = state_data.get('Raining')
rain_24hr = state_data.get('Rain24')
rain_48hr = state_data.get('Rain48')
last_updated = d.get('last_updated')
print(f'Temperature: {temperature}°F')
print(f'Humidity: {humidity}%')
print(f'Wind: {wind_speed} mph {wind_dir}')
print(f'Wind peak 24hr: {wind_speed_peak} mph')
print(f'Temp peak 24hr: {temp_peak_24hr}°F')
print(f'Raining: {raining}')
print(f'Rain 24hr: {rain_24hr} in')
print(f'Rain 48hr: {rain_48hr} in')
print(f'Last updated: {last_updated}')
'''

(e.g. "what\'s the temperature?"), extract just that field.
If asked for "wind", respond with WindSpeed and WinDir (wind direction).
If the user doesn't provide specific weather attributes, respond with Temperature and WindSpeed only.
If curl fails or returns no data, say the weather station is unreachable and include any error details you have.
Present the results conversationally. If the user asks for a specific reading only

