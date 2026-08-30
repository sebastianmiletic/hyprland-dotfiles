#!/usr/bin/env bash
# Brightness controls with clean wob OSD

STEP="${2:-10}"
case "${1:-}" in
    --inc)
        brightnessctl set "+${STEP}%"
        ;;
    --dec)
        brightnessctl set "${STEP}%-"
        ;;
    *)
        ;;
esac

level=$(brightnessctl -m | cut -d, -f4 | tr -d '%')
"$HOME/.config/hypr/scripts/ShowOSD.sh" "$level"
