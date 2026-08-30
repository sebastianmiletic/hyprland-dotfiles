#!/usr/bin/env bash
# Clean compact horizontal power menu at the bottom center

if pgrep -x "wlogout" > /dev/null; then
    pkill -x "wlogout"
    exit 0
fi

wlogout --protocol layer-shell \
    --layout "$HOME/.config/wlogout/layout" \
    --css "$HOME/.config/wlogout/style.css" \
    -b 4 \
    -T 900 -B 40 \
    &
disown
