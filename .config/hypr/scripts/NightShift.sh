#!/usr/bin/env bash
# Permanent warm night shift using wlsunset
set -euo pipefail

if pgrep -x "wlsunset" > /dev/null; then
    pkill -x "wlsunset"
    exit 0
fi

# Temperature: 4500K warm, long transition
exec wlsunset -T 6500 -t 4500 -d 900 -S 6:00 -s 18:00
