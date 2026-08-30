#!/usr/bin/env bash
# Reset cursor / mouse / trackpad (soft + kernel reload)

# Soft reset via hyprctl/gsettings
export XCURSOR_THEME=Bibata-Modern-Classic
export XCURSOR_SIZE=48
hyprctl setcursor Bibata-Modern-Classic 48
gsettings set org.gnome.desktop.interface cursor-theme 'Bibata-Modern-Classic' 2>/dev/null || true
gsettings set org.gnome.desktop.interface cursor-size 48 2>/dev/null || true

# Try pkexec for kernel module reload
reload_modules() {
    modprobe -r hid_multitouch 2>/dev/null; modprobe hid_multitouch
    modprobe -r psmouse 2>/dev/null; modprobe psmouse
    modprobe -r usbhid 2>/dev/null; modprobe usbhid
    modprobe -r wacom 2>/dev/null; modprobe wacom
}

if command -v pkexec >/dev/null 2>&1; then
    pkexec bash -c "$(declare -f reload_modules); reload_modules" 2>/dev/null || true
fi

notify-send -a "Cursor Reset" "Cursor reloaded" "Theme: Bibata-Modern-Classic @ 48px"
