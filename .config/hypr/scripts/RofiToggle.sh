#!/usr/bin/env bash
# Toggle rofi app launcher
if pgrep -x rofi >/dev/null; then
    pkill -x rofi
else
    rofi -show drun -modi drun,filebrowser,run,window -config "$HOME/.config/rofi/launcher-dark.rasi"
fi
