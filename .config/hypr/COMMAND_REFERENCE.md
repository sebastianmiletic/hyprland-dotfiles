# Hyprland Full Command Reference
# Your setup uses Lua-based config: ~/.config/hypr/hyprland.lua

## Core Desktop Keybinds

| Keybind | Action |
|---------|--------|
| **SUPER + Space** | Spotlight-style app launcher (fuzzel, no windows) |
| **SUPER + SUPER_L / SUPER_R** | App launcher fallback (fuzzel) |
| **SUPER + Q** | Close active window |
| **SUPER + SHIFT + Q** | Forcefully zap (kill) a window |
| **ALT + F4** | Shows "Use Super+Q" notification (disabled intentionally) |
| **SUPER + W** | **Wallpaper changer** (clean rofi grid) |
| **SUPER + Return** | Terminal |
| **SUPER + T** | Terminal (alt) |
| **CTRL + ALT + T** | Terminal (alt) |
| **SUPER + E** | File manager |
| **SUPER + C** | Code editor |
| **SUPER + X** | Text editor |
| **SUPER + I** | Settings app |
| **CTRL + SUPER + V** | Volume mixer |
| **CTRL + SHIFT + Escape** | Task manager |
| **SUPER + L** | Lock screen |
| **SUPER + SHIFT + L** | Sleep / Suspend |

## Window Management

| Keybind | Action |
|---------|--------|
| **SUPER + Arrow Keys** | Focus window in direction |
| **SUPER + SHIFT + Arrow Keys** | Move window in direction |
| **SUPER + [ / ]** | Focus left / right |
| **SUPER + ALT + Space** | Toggle float / tile |
| **SUPER + D** | Toggle maximize |
| **SUPER + F** | Toggle fullscreen |
| **SUPER + ALT + F** | Fullscreen spoof |
| **SUPER + P** | Pin window |
| **SUPER + mouse:272** (LMB drag) | Move window |
| **SUPER + mouse:273** (RMB drag) | Resize window |
| **SUPER + Semicolon** | Decrease split ratio |
| **SUPER + Apostrophe** | Increase split ratio |

## Workspace Keybinds

| Keybind | Action |
|---------|--------|
| **SUPER + 1-0** | Focus workspace 1-10 |
| **SUPER + ALT + 1-0** | Send window to workspace 1-10 |
| **ALT + Left / Right** | Previous / next workspace |
| **CTRL + SUPER + Left / Right** | Focus workspace left / right |
| **SUPER + Page Up / Down** | Focus workspace left / right |
| **SUPER + S** | Toggle scratchpad (special workspace) |
| **SUPER + ALT + S** | Send window to scratchpad |
| **CTRL + SUPER + S** | Toggle special workspace |

## System & Utilities

| Keybind | Action |
|---------|--------|
| **SUPER + V** | Clipboard history (or overview) |
| **SUPER + Period** | Emoji picker |
| **SUPER + Shift + S** | Screen snip (region screenshot) |
| **Print** | Fullscreen screenshot to clipboard |
| **CTRL + Print** | Screenshot to clipboard & file |
| **SUPER + SHIFT + C** | Color picker (hyprpicker) |
| **SUPER + SHIFT + R** | Record region |
| **SUPER + SHIFT + ALT + R** | Record fullscreen with sound |
| **SUPER + SHIFT + X** | OCR selected region |
| **SUPER + SHIFT + T** | Translate screen content |
| **SUPER + Minus** | Zoom out |
| **SUPER + Equal** | Zoom in |
| **SUPER + ALT + mouse_down** | Zoom in (mouse wheel) |
| **SUPER + ALT + mouse_up** | Zoom out (mouse wheel) |
| **CTRL + SUPER + C** | **Reset cursor / mouse / trackpad** |
| **CTRL + SUPER + R** | Restart quickshell widgets |
| **CTRL + ALT + Delete** | Session menu (wlogout) |
| **CTRL + SHIFT + ALT + SUPER + Delete** | Power off |

## Media Keys

| Keybind | Action |
|---------|--------|
| **XF86AudioRaiseVolume** | Volume up |
| **XF86AudioLowerVolume** | Volume down |
| **XF86AudioMute** | Toggle mute |
| **XF86AudioMicMute** | Toggle mic mute |
| **XF86AudioPlayPause** | Play / Pause |
| **XF86AudioNext** | Next track |
| **XF86AudioPrev** | Previous track |
| **SUPER + SHIFT + P** | Play / Pause media |
| **SUPER + SHIFT + N** | Next track |
| **SUPER + SHIFT + B** | Previous track |
| **SUPER + SHIFT + M** | Toggle mute |
| **SUPER + ALT + M** | Toggle mic |
| **XF86MonBrightnessUp** | Brightness up |
| **XF86MonBrightnessDown** | Brightness down |

## Mouse / Trackpad / Cursor Recovery Commands

If your cursor / mouse / trackpad stops working:

```bash
# 1. Soft reset via hyprctl (run in terminal)
hyprctl setcursor Bibata-Modern-Classic 24

# 2. Reset gsettings cursor theme
gsettings set org.gnome.desktop.interface cursor-theme 'Bibata-Modern-Classic'
gsettings set org.gnome.desktop.interface cursor-size 24

# 3. Custom reset script (also bound to CTRL+SUPER+C)
~/.config/hypr/custom/scripts/reset-cursor.sh

# 4. Kernel-level reload (requires sudo)
sudo modprobe -r hid_multitouch 2>/dev/null; sudo modprobe hid_multitouch
sudo modprobe -r psmouse 2>/dev/null; sudo modprobe psmouse
sudo modprobe -r usbhid 2>/dev/null; sudo modprobe usbhid

# 5. Wacom / tablet specific (if applicable)
sudo modprobe -r wacom 2>/dev/null; sudo modprobe wacom

# 6. Full input subsystem reset (nuclear option)
sudo rmmod hid_generic 2>/dev/null; sudo modprobe hid_generic
sudo rmmod hid 2>/dev/null; sudo modprobe hid

# 7. Restart Hyprland (last resort)
hyprctl dispatch exit 0
```

## Config Files Reference

| File | Purpose |
|------|---------|
| `~/.config/hypr/hyprland.lua` | **Main config entry point** |
| `~/.config/hypr/hyprland/general.lua` | General settings, animations, input |
| `~/.config/hypr/hyprland/keybinds.lua` | Default keybinds |
| `~/.config/hypr/hyprland/execs.lua` | Startup apps |
| `~/.config/hypr/hyprland/rules.lua` | Window / workspace / layer rules |
| `~/.config/hypr/custom/general.lua` | **Your custom input/cursor overrides** |
| `~/.config/hypr/custom/keybinds.lua` | **Your custom keybinds** |
| `~/.config/hypr/custom/execs.lua` | **Your custom startup fixes** |
| `~/.config/hypr/custom/scripts/wallpaper-changer.sh` | **Wallpaper changer script** |
| `~/.config/hypr/custom/scripts/reset-cursor.sh` | **Cursor reset script** |
| `~/.config/rofi/wallpaper-spotlight.rasi` | Wallpaper changer UI theme |
