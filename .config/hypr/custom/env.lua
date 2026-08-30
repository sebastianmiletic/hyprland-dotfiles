-- App scaling (1.25x for GTK/Qt/EFL apps, does NOT affect kitty/opencode TUI)
hl.env("GDK_SCALE", "1.25")
hl.env("GDK_DPI_SCALE", "1.25")
hl.env("QT_SCALE_FACTOR", "1.25")
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1.25")
hl.env("ELM_SCALE", "1.25")

-- Nuclear cursor fix: force software cursors BEFORE hyprland init
hl.env("WLR_NO_HARDWARE_CURSORS", "1")

-- Keep existing envs
local home_dir = os.getenv("HOME")
local xdg_data_dirs_old = os.getenv("XDG_DATA_DIRS") or ""
hl.env("XDG_DATA_DIRS", home_dir .. "/.local/share/flatpak/exports/share:/var/lib/flatpak/exports/share:/usr/local/share:/usr/share:" .. xdg_data_dirs_old)
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("XDG_MENU_PREFIX", "gnome-")
hl.env("ILLOGICAL_IMPULSE_VIRTUAL_ENV", home_dir .. "/.local/state/quickshell/.venv")
