# Multi-rice switching plan

## Goal

Keep every rice as an independent Quickshell configuration and use a small,
stable Quickshell picker on `Super+R`. A failed rice must never leave the
desktop without a shell.

## Directory layout

```text
~/.config/quickshell/
├── ii/                  # current rice
├── <next-rice>/         # the new visual design
└── rice-picker/         # tiny independent Super+R picker

~/.config/hypr/rices/
├── ii.lua               # optional rice-specific Hyprland rules
└── <next-rice>.lua

~/.local/share/rices/
├── ii.json              # name, Quickshell config, preview, accent
└── <next-rice>.json

~/.local/state/rice/active
```

Wallpapers, user files, Kitty, browsers and other applications remain shared.
Only shell visuals and explicitly rice-specific Hyprland rules are isolated.

## Picker and switch transaction

1. `Super+R` launches `qs -c rice-picker --no-duplicate`.
2. The picker reads the JSON entries and shows a compact preview list with
   typing, arrow-key navigation and Enter to choose.
3. A detached `rice-switch <name>` helper checks that the target has a
   readable `shell.qml` and registry entry.
4. It starts the target with `qs -c <name> --daemonize --no-duplicate` while
   the current rice is still alive.
5. It waits up to eight seconds for the target instance to appear in
   `qs list --all`. If that fails, it stops the failed target and leaves the
   current rice untouched.
6. Once healthy, it writes the active-rice state atomically, loads the optional
   Hyprland fragment, reloads Hyprland, checks `hyprctl configerrors`, and then
   stops only the previous Quickshell config.
7. If the Hyprland fragment is invalid, it restores the previous fragment and
   rice before reporting the error.

The picker is a third, intentionally tiny Quickshell config so it is not killed
halfway through replacing the currently selected rice.

## Shared command wrapper

Add `~/.local/bin/qs-active`, which reads `~/.local/state/rice/active` and sends
IPC to that config. Hyprland shortcuts such as wallpaper, lock, Spotlight and
session menus should call this wrapper rather than hard-code `ii`. Startup uses
the same active-state file, making the selected rice survive logout and reboot.

## Build order

1. Create the new rice as `~/.config/quickshell/<next-rice>/shell.qml` and give
   its layers unique namespaces while developing it alongside `ii`.
2. Add the registry format, `qs-active`, and the transactional `rice-switch`
   helper with rollback tests.
3. Build `rice-picker` in Quickshell using the same minimal search/list language
   as the wallpaper gallery.
4. Bind `Super+R` only after two configs pass start, switch, rollback, lock,
   wallpaper and logout/login tests.
5. Move genuinely shared QML helpers into a versioned shared module only after
   both rices need them; do not symlink entire config trees.

## Acceptance checks

- Repeated `ii -> new -> ii` switching produces one instance of the active rice.
- A deliberately broken target leaves the current rice and shortcuts working.
- `Super+W`, `Super+Space`, lock and session controls target the active rice.
- The selected rice returns after logout/reboot.
- An invalid rice-specific Hyprland rule automatically rolls back with zero
  remaining `hyprctl configerrors`.
