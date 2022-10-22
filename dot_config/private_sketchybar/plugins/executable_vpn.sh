#!/usr/bin/env bash

vpn_state=$(osascript -e "tell application \"/Applications/Tunnelblick.app\"" -e "get state of first configuration where name = \"vpn03\"" -e "end tell")

echo $vpn_state


if [ $vpn_state = "CONNECTED" ]; then
    sketchybar --set vpn icon.color="0xffa6da95" label.color="0xffa6da95"
else
    sketchybar --set vpn icon.color="0xffed8796" label.color="0xffed8796"
fi
