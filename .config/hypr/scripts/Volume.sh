#!/usr/bin/env bash
# Volume controls with clean wob OSD

case "${1:-}" in
    --inc)
        pamixer -i "${2:-5}" --allow-boost --set-limit 150
        ;;
    --inc-precise)
        pamixer -i "${2:-2}" --allow-boost --set-limit 150
        ;;
    --dec)
        pamixer -d "${2:-5}"
        ;;
    --dec-precise)
        pamixer -d "${2:-2}"
        ;;
    --toggle)
        pamixer -t
        ;;
    --toggle-mic)
        pamixer --default-source -t
        ;;
    *)
        ;;
esac

level=$(pamixer --get-volume)
if [[ "$(pamixer --get-mute)" == "true" ]]; then
    level=0
fi
"$HOME/.config/hypr/scripts/ShowOSD.sh" "$level"
