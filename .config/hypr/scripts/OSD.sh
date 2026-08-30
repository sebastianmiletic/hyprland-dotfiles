#!/usr/bin/env bash
# Central OSD launcher for wob
export PATH="$HOME/.local/bin:$PATH"
WOBSOCK="$XDG_RUNTIME_DIR/wob.sock"
mkdir -p "$(dirname "$WOBSOCK")"
[ -e "$WOBSOCK" ] || mkfifo "$WOBSOCK"
if ! pgrep -x "wob" > /dev/null; then
    wob --config "$HOME/.config/wob/wob.ini" < "$WOBSOCK" &
fi
