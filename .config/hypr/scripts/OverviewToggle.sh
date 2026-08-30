#!/usr/bin/env bash

# Overview toggle wrapper - uses Quickshell's overview config

set -euo pipefail

# 1) If quickshell daemon is running, toggle via IPC on the overview config
if pgrep -x quickshell >/dev/null 2>&1 || pgrep -x qs >/dev/null 2>&1; then
  if qs ipc -c overview call overview toggle >/dev/null 2>&1; then
    exit 0
  fi
fi

# 2) Not running: start the overview config daemonized and toggle
if command -v qs > /dev/null 2>&1; then
  qs -c overview -d >/dev/null 2>&1 &
  sleep 0.8
  if qs ipc -c overview call overview toggle >/dev/null 2>&1; then
    exit 0
  fi
fi

# 3) If we get here, quickshell failed to start or respond
notify-send "Overview" "Quickshell is not responding" -u low 2>/dev/null || true
exit 1
