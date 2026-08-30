#!/usr/bin/env bash
# Refresh bar and menus for base Hyprland

SCRIPTSDIR=$HOME/.config/hypr/scripts
UserScripts=$HOME/.config/hypr/UserScripts

_ps=(waybar rofi swaync ags)
for _prs in "${_ps[@]}"; do
    if pidof "${_prs}" >/dev/null 2>&1; then
        pkill "${_prs}" 2>/dev/null || true
    fi
done

killall -SIGUSR2 waybar 2>/dev/null || true
sleep 0.1

for pid in $(pidof waybar rofi swaync ags swaybg 2>/dev/null); do
    kill -SIGUSR1 "$pid" 2>/dev/null || true
    sleep 0.1
done

sleep 0.1
waybar &

sleep 0.3
swaync >/dev/null 2>&1 &
swaync-client --reload-config 2>/dev/null || true

sleep 1
if [[ -x "${UserScripts}/RainbowBorders.sh" ]]; then
    ${UserScripts}/RainbowBorders.sh &
fi

exit 0
