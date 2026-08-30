# Sebastian's Hyprland dotfiles

Personal Arch Linux desktop configuration built around Hyprland and
[illogical-impulse Quickshell](https://github.com/end-4/dots-hyprland).

## Highlights

- Hyprland Lua configuration and custom keybindings
- Quickshell bars, sidebars, launcher, widgets, and settings
- Integrated Google Tasks sidebar through GNOME Online Accounts
- `Super+Z` Gemini answer for highlighted text, with screen-question fallback
- Kitty, Foot, Zsh, Fastfetch, Fuzzel, Rofi, Dunst, and related UI configs

## Install

Review the files before applying them. From the repository root, copy the
configuration you want into your home directory, for example:

```bash
rsync -av --dry-run .config/hypr/ ~/.config/hypr/
rsync -av --dry-run .config/quickshell/ ~/.config/quickshell/
```

Remove `--dry-run` only after checking the proposed changes.

The main shell requires Hyprland, Quickshell, and the programs referenced by
the configuration. The embedded task integration additionally uses
`gnome-online-accounts`, `gnome-control-center`, and the Google Tasks API.

## Private data

Credentials, API keys, OAuth tokens, browser data, histories, and generated
runtime state are intentionally excluded. Configure accounts and secrets
locally after installation.

