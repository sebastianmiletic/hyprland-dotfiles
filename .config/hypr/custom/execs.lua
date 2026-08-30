-- Cursor, touchpad, automount, and device startup fixes
hl.on("hyprland.start", function ()
    -- Keep the settings UI loaded but hidden so Super+I appears instantly.
    hl.exec_cmd("II_SETTINGS_PRELOAD=1 qs -p ~/.config/quickshell/ii/settings.qml -d &")

    -- Force software cursor (nuclear fix for invisible cursor)
    hl.exec_cmd("hyprctl keyword cursor:no_hardware_cursors true")

    -- Reset cursor theme and size
    hl.exec_cmd("hyprctl setcursor Bibata-Modern-Classic 24")
    hl.exec_cmd("gsettings set org.gnome.desktop.interface cursor-theme 'Bibata-Modern-Classic' 2>/dev/null || true")
    hl.exec_cmd("gsettings set org.gnome.desktop.interface cursor-size 24 2>/dev/null || true")

    -- Ensure env is exported for child processes
    hl.exec_cmd("export XCURSOR_THEME=Bibata-Modern-Classic; export XCURSOR_SIZE=24")

    -- Explicitly enable wacom finger/pen if present
    hl.exec_cmd("hyprctl keyword device:wacom-hid-4a0d-finger:enabled true 2>/dev/null || true")
    hl.exec_cmd("hyprctl keyword device:wacom-hid-4a0d-pen:enabled true 2>/dev/null || true")

    -- USB automount (udiskie) -- shows USB devices in Nautilus
    hl.exec_cmd("udiskie --no-notify --smart-tray &")

    -- Start polkit agent for mount/auth dialogs
    hl.exec_cmd("/usr/lib/hyprpolkitagent/hyprpolkitagent &")

    -- Set Brave as default browser
    hl.exec_cmd("xdg-settings set default-web-browser brave-browser.desktop")
end)
