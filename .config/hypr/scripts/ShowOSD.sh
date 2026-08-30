#!/usr/bin/env bash
# Show a clean wob OSD bar for a single value (0-100)
value="${1:-0}"
[ -z "$value" ] && exit 0

# Kill any existing wob OSD to avoid overlap
pkill -x wob 2>/dev/null || true

# Feed the value into wob and keep stdin open long enough for the bar to display
( printf '%s\n' "$value"; sleep 2 ) | wob --config "$HOME/.config/wob/wob.ini" 2>/dev/null
