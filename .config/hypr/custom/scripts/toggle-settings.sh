#!/usr/bin/env bash

settings_qml="$HOME/.config/quickshell/ii/settings.qml"

if qs ipc -p "$settings_qml" call settings toggle >/dev/null 2>&1; then
    exit 0
fi

II_SETTINGS_PRELOAD=1 qs -p "$settings_qml" -d >/dev/null 2>&1
for _ in {1..30}; do
    if qs ipc -p "$settings_qml" call settings show >/dev/null 2>&1; then
        exit 0
    fi
    sleep 0.05
done

notify-send "Settings" "The settings interface could not be started."
