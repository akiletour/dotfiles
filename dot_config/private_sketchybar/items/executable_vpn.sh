#!/usr/bin/env sh

sketchybar   --add item     vpn right \
             --set vpn  icon=$MAIL \
                        label="VPN" \
                        icon= \
                        icon.padding_left=18 \
                        icon.font="Hack Nerd Font:Regular:16.0" \
                        icon.color=$WHITE \
                        click_script='osascript -e "tell application \"/Applications/Tunnelblick.app\"" -e "connect \"vpn03\"" -e "end tell"' \
