#!/usr/bin/env bash

set -u

readonly suspend_delay=15
shopt -s nullglob
lid_state_files=(/proc/acpi/button/lid/*/state)

if (( ${#lid_state_files[@]} == 0 )); then
    echo "No ACPI lid state file found" >&2
    exit 1
fi

lid_state_file="${lid_state_files[0]}"
closed_at=0

echo "Watching ${lid_state_file}; suspending after ${suspend_delay}s closed"

while true; do
    read -r _ lid_state < "${lid_state_file}" || lid_state="unknown"

    if [[ "${lid_state}" == "closed" ]]; then
        if (( closed_at == 0 )); then
            closed_at=$SECONDS
            echo "Lid closed; suspend countdown started"
        elif (( SECONDS - closed_at >= suspend_delay )); then
            echo "Lid remained closed for ${suspend_delay}s; suspending"
            closed_at=0
            loginctl lock-session
            systemctl suspend
        fi
    else
        if (( closed_at != 0 )); then
            echo "Lid reopened before suspend; countdown cancelled"
        fi
        closed_at=0
    fi

    sleep 1
done
