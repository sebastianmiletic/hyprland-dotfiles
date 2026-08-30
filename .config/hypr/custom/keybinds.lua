local hyprScripts = "$HOME/.config/hypr/hyprland/scripts"
local qsIsAlive = "pidof qs quickshell >/dev/null"

-- Super+Space toggles the overview (what used to show on just Super)
hl.bind("SUPER + Space", hl.dsp.global("quickshell:overviewWorkspacesToggle"), { description = "Shell: Toggle overview" })

-- Disable old double-tap Super search (override with no-op)
hl.bind("SUPER + SUPER_L", hl.dsp.exec_cmd("true"))
hl.bind("SUPER + SUPER_R", hl.dsp.exec_cmd("true"))

-- Browser moved to Super+B
hl.bind("SUPER + B", hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/launch_first_available.sh 'brave' 'brave-browser' 'google-chrome-stable' 'zen-browser' 'firefox' 'chromium' 'microsoft-edge-stable' 'opera' 'librewolf'"), { description = "App: Brave browser" })

-- Use the shell-native gallery. The second binding starts Quickshell if it is
-- not already available, so the shortcut also recovers from a shell crash.
hl.bind("SUPER + W", hl.dsp.global("quickshell:wallpaperSelectorToggle"), { description = "Shell: Wallpaper gallery" })
hl.bind("SUPER + W", hl.dsp.exec_cmd(qsIsAlive .. " || qs -c $qsConfig"))

-- Answer highlighted text when available; otherwise answer what is on screen.
hl.bind("SUPER + Z", hl.dsp.global("quickshell:screenAnswer"), { description = "AI: Answer selection or screen question" })

-- Alt+Tab window cycling
hl.bind("ALT + Tab", hl.dsp.exec_cmd("hyprctl dispatch cyclenext"), { description = "Window: Cycle next" })
hl.bind("SHIFT + ALT + Tab", hl.dsp.exec_cmd("hyprctl dispatch cyclenext prev"), { description = "Window: Cycle previous" })

-- Force cursor / mouse / trackpad reset
hl.bind("CTRL + SUPER + C", hl.dsp.exec_cmd("$HOME/.config/hypr/custom/scripts/reset-cursor.sh"), { description = "System: Reset cursor" })
