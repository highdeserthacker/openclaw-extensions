---
name: my_location
description: Gets the user's current location, including GPS position, and friendly name for common places. Use this skill when needing location context for the user, e.g. things nearby. Use also to know if the user is home or at a known place (e.g. "home", "gym", "grocery store").
metadata: {"openclaw":{"requires":{"bins":["curl"],"env":["HA_TOKEN"]}}}
---
# My Location

Fetch all current readings:
```bash
curl -s http://10.0.0.22:8123/api/states/device_tracker.owntracks_billsphone \
  -H "Authorization: Bearer ${HA_TOKEN}" \
  | python3 -c "
import json, sys
d = json.load(sys.stdin)
a = d['attributes']
print(f\"State: {d['state']}\")
print(f\"Latitude/Longitude: {a['latitude']}, {a['longitude']}\")
print(f\"LastPositionUpdate: {d['last_updated']}\")
"
'''

## Triggers
Activate this skill when the user asks:
- "what things are nearby"
- "what good lunch places are nearby"

Also activate this skill if you need to know if the user is home.

## Guidelines for using the location information

Use this skill to know where the user is located. If state is not blank, it is a common location and you can refer to it with this name if appropriate to the conversation.
If asked a question relating to things nearby, use this location. For example, the user may ask for a coffee shop nearby, or a gas station, or restaurant.
If LastPositionUpdate is more than a day old, location information may not be up-to-date, confirm my location first by name, based on a map (not gps coordinates) with where you think I am.
I may tell you to remember this location and give it a name. If so, save this in your memory. 
If curl fails, say "Home Assistant not currently available".


