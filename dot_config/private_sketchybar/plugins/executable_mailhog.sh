#!/usr/bin/env sh

API_MAILHOG="http://localhost:8025/api/v2/messages"

COUNT=$(curl -s $API_MAILHOG | jq '.count')

echo $COUNT

sketchybar --set mailhog label=$COUNT
