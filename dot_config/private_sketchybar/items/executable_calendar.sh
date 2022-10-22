#!/usr/bin/env sh

sketchybar --add item     calendar right                         \
           --set calendar icon=cal                               \
                          icon.color=$BLACK                      \
                          icon.font="$FONT:Black:12.0"           \
                          icon.padding_left=5                    \
                          icon.padding_right=5                   \
                          label.color=$BLACK                     \
                          label.padding_left=5                   \
                          label.padding_right=5                  \
                          width=140                              \
                          align=center                           \
                          background.color=$CALENDAR_BACKGROUND  \
                          background.height=26                   \
                          background.corner_radius=11

sketchybar   --add item     mailhog right \
             --set mailhog  icon=$MAIL \
                            icon.font="Hack Nerd Font:Regular:16.0" \
                            icon.color=$WHITE \
                            click_script="open http://127.0.0.1:8025" \
                            script="$PLUGIN_DIR/mailhog.sh" \
                            update_freq=10 \
