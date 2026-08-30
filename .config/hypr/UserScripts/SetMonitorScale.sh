#!/usr/bin/env bash
# Force monitor scale to 1.0 on each login because Hyprland auto-scales eDP-1 to 1.5.
sleep 1
wlr-randr --output eDP-1 --scale 1.0 2>/dev/null || true
