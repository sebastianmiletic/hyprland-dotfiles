#!/usr/bin/env bash
# Wallpaper Changer — applies wallpaper via awww and updates theming

PICTURES_DIR="$(xdg-user-dir PICTURES 2>/dev/null || echo "$HOME/Pictures")"
WALLDIR="$PICTURES_DIR/wallpapers"
SCRIPTSDIR="$HOME/.config/hypr/scripts"
ROFI_THEME="$HOME/.config/rofi/wallpaper-spotlight.rasi"

focused_monitor=$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name')

if [[ -z "$focused_monitor" ]]; then
  notify-send -a "Wallpaper" "Error" "Could not detect focused monitor"
  exit 1
fi

# Kill conflicting wallpaper daemons ONLY (NOT awww-daemon)
kill_conflicting() {
  pkill mpvpaper 2>/dev/null
  pkill swaybg 2>/dev/null
  pkill hyprpaper 2>/dev/null
}

# Retrieve wallpapers (flat directory, no subdirs)
mapfile -d '' PICS < <(find -L "${WALLDIR}" -maxdepth 1 -type f \( \
  -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" -o \
  -iname "*.bmp" -o -iname "*.tiff" -o -iname "*.webp" \) -print0)

if [[ ${#PICS[@]} -eq 0 ]]; then
  notify-send -a "Wallpaper" "Error" "No wallpapers found in $WALLDIR"
  exit 1
fi

RANDOM_PIC="${PICS[$((RANDOM % ${#PICS[@]}))]}"
RANDOM_PIC_NAME=". random"

rofi_command="rofi -dmenu -i -no-custom -cycle -p '' -config $ROFI_THEME"

menu() {
  IFS=$'\n' sorted_options=($(sort <<<"${PICS[*]}"))
  printf "%s\x00icon\x1f%s\n" "$RANDOM_PIC_NAME" "$RANDOM_PIC"

  for pic_path in "${sorted_options[@]}"; do
    pic_name=$(basename "$pic_path")
    if [[ "$pic_name" =~ \.gif$ ]]; then
      cache_gif_image="$HOME/.cache/gif_preview/${pic_name}.png"
      if [[ ! -f "$cache_gif_image" ]]; then
        mkdir -p "$HOME/.cache/gif_preview"
        magick "$pic_path[0]" -resize 640x480 "$cache_gif_image"
      fi
      printf "%s\x00icon\x1f%s\n" "$pic_name" "$cache_gif_image"
    else
      printf "%s\x00icon\x1f%s\n" "$pic_name" "$pic_path"
    fi
  done
}

apply_wallpaper() {
  local image_path="$1"
  kill_conflicting

  # Ensure awww-daemon is running
  if ! pgrep -x "awww-daemon" >/dev/null; then
    awww-daemon --format xrgb &
    sleep 2
  fi

  # Apply wallpaper using awww (system standard)
  awww img -o "$focused_monitor" "$image_path" \
    --transition-fps 60 \
    --transition-type any \
    --transition-duration 2 \
    --transition-bezier ".43,1.19,1,.4"

  # Update quickshell config so its background knows about the new wallpaper
  SHELL_CONFIG_FILE="$HOME/.config/illogical-impulse/config.json"
  if [ -f "$SHELL_CONFIG_FILE" ]; then
    jq --arg path "$image_path" '.background.wallpaperPath = $path | .background.thumbnailPath = ""' "$SHELL_CONFIG_FILE" > "$SHELL_CONFIG_FILE.tmp" && mv "$SHELL_CONFIG_FILE.tmp" "$SHELL_CONFIG_FILE"
  fi

  # Notify
  notify-send -a "Wallpaper" "Wallpaper changed" "$(basename "$image_path")" -i "$image_path"

  # Update colors and refresh
  "$SCRIPTSDIR/WallustSwww.sh" "$image_path" &
  # Wait for transition to finish before refreshing UI
  sleep 3
  "$SCRIPTSDIR/RefreshNoWaybar.sh"
}

# Main
choice=$(menu | $rofi_command)
choice=$(echo "$choice" | xargs)
RANDOM_PIC_NAME=$(echo "$RANDOM_PIC_NAME" | xargs)

if [[ -z "$choice" ]]; then
  exit 0
fi

if [[ "$choice" == "$RANDOM_PIC_NAME" ]]; then
  choice=$(basename "$RANDOM_PIC")
fi

choice_basename=$(basename "$choice" | sed 's/\(.*\)\.[^.]*$/\1/')
selected_file=$(find "$WALLDIR" -maxdepth 1 -iname "$choice_basename.*" -print -quit)

if [[ -z "$selected_file" ]]; then
  notify-send -a "Wallpaper" "Error" "Could not find file: $choice"
  exit 1
fi

apply_wallpaper "$selected_file"
