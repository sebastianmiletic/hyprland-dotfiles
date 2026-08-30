#!/usr/bin/env bash

# Rofi Themes - Script to preview and apply themes with image previews.

# --- Configuration ---
ROFI_THEMES_DIR_CONFIG="$HOME/.config/rofi/themes"
ROFI_THEMES_DIR_LOCAL="$HOME/.local/share/rofi/themes"
ROFI_CONFIG_FILE="$HOME/.config/rofi/config.rasi"
ROFI_THEME_FOR_THIS_SCRIPT="$HOME/.config/rofi/config-rofi-theme-preview.rasi"
PREVIEW_DIR="$HOME/.config/rofi/previews"

mkdir -p "$PREVIEW_DIR"

# --- Helper Functions ---

notify_user() {
  local icon="$1"
  local title="$2"
  local body="$3"
  notify-send -u low -i "$icon" "$title" "$body" 2>/dev/null || true
}

apply_rofi_theme_to_config() {
  local theme_name_to_apply="$1"

  local theme_path
  if [[ -f "$ROFI_THEMES_DIR_CONFIG/$theme_name_to_apply" ]]; then
    theme_path="$ROFI_THEMES_DIR_CONFIG/$theme_name_to_apply"
  elif [[ -f "$ROFI_THEMES_DIR_LOCAL/$theme_name_to_apply" ]]; then
    theme_path="$ROFI_THEMES_DIR_LOCAL/$theme_name_to_apply"
  else
    notify_user "dialog-error" "Error" "Theme file not found: $theme_name_to_apply"
    return 1
  fi

  local theme_path_with_tilde="~${theme_path#$HOME}"

  local temp_rofi_config_file
  temp_rofi_config_file=$(mktemp)
  cp "$ROFI_CONFIG_FILE" "$temp_rofi_config_file"

  # Comment out any existing @theme entry
  sed -i -E 's/^([[:space:]]*@theme)/\/\/\1/' "$temp_rofi_config_file"

  # Add the new @theme entry at the end of the file
  printf '\n@theme "%s"\n' "$theme_path_with_tilde" >> "$temp_rofi_config_file"

  # Overwrite the original config file
  cp "$temp_rofi_config_file" "$ROFI_CONFIG_FILE"
  rm "$temp_rofi_config_file"

  # Prune old commented-out theme lines to prevent clutter
  local max_lines=10
  local total_lines
  total_lines=$(grep -c '^[[:space:]]*\/\/\s*@theme' "$ROFI_CONFIG_FILE" 2>/dev/null || true)
  if [[ "$total_lines" =~ ^[0-9]+$ ]] && (( total_lines > max_lines )); then
    local excess=$((total_lines - max_lines))
    for ((i = 1; i <= excess; i++)); do
      sed -i '0,/^[[:space:]]*\/\/\s*@theme/s///' "$ROFI_CONFIG_FILE"
    done
  fi

  return 0
}

# Ensure the picker theme shows icons and styled text.
write_preview_theme() {
  cat > "$ROFI_THEME_FOR_THIS_SCRIPT" <<'EOF'
@import "~/.config/rofi/config.rasi"

configuration {
    show-icons: true;
}

window {
    width: 800px;
    height: 600px;
    border: 2px;
    border-radius: 18px;
    padding: 20px;
}

mainbox {
    children: [ "inputbar", "message", "listview" ];
}

inputbar {
    children: [ prompt, entry ];
    spacing: 10px;
    margin: 0 0 10px 0;
}

entry {
    placeholder: "Search theme...";
}

message {
    padding: 10px;
    border-radius: 10px;
}

listview {
    columns: 2;
    lines: 4;
    spacing: 12px;
    fixed-height: false;
    scrollbar: false;
    cycle: true;
}

element {
    orientation: vertical;
    padding: 10px;
    border-radius: 14px;
    spacing: 8px;
    children: [ element-icon, element-text ];
}

element-icon {
    size: 220px;
    border-radius: 10px;
}

element-text {
    font: "Inter 14";
    horizontal-align: 0.5;
    vertical-align: 0.5;
}

element selected {
    border: 2px;
}
EOF
}

# --- Main Script Execution ---

if [[ ! -d "$ROFI_THEMES_DIR_CONFIG" && ! -d "$ROFI_THEMES_DIR_LOCAL" ]]; then
  notify_user "dialog-error" "E-R-R-O-R" "No Rofi themes directory found."
  exit 1
fi

if [[ ! -f "$ROFI_CONFIG_FILE" ]]; then
  notify_user "dialog-error" "E-R-R-O-R" "Rofi config file not found: $ROFI_CONFIG_FILE"
  exit 1
fi

write_preview_theme

# Backup the original config content
original_rofi_config_content_backup=$(cat "$ROFI_CONFIG_FILE")

# Generate a sorted list of available theme file names
mapfile -t available_theme_names < <((
  find "$ROFI_THEMES_DIR_CONFIG" -maxdepth 1 -name "*.rasi" -type f -printf "%f\n" 2>/dev/null
  find "$ROFI_THEMES_DIR_LOCAL" -maxdepth 1 -name "*.rasi" -type f -printf "%f\n" 2>/dev/null
) | sort -V -u)

if [[ ${#available_theme_names[@]} -eq 0 ]]; then
  notify_user "dialog-error" "No Rofi Themes" "No .rasi files found in theme directories."
  exit 1
fi

# Find the currently active theme to set as the initial selection
current_selection_index=0
current_active_theme_path=$(grep -oP '^[[:space:]]*@theme\s*"\K[^"]+' "$ROFI_CONFIG_FILE" | tail -n 1)
if [[ -n "$current_active_theme_path" ]]; then
  current_active_theme_name=$(basename "$current_active_theme_path")
  for i in "${!available_theme_names[@]}"; do
    if [[ "${available_theme_names[$i]}" == "$current_active_theme_name" ]]; then
      current_selection_index=$i
      break
    fi
  done
fi

# Main preview loop
while true; do
  theme_to_preview_now="${available_theme_names[$current_selection_index]}"

  # Apply the theme for preview
  if ! apply_rofi_theme_to_config "$theme_to_preview_now"; then
    echo "$original_rofi_config_content_backup" > "$ROFI_CONFIG_FILE"
    notify_user "dialog-error" "Preview Error" "Failed to apply $theme_to_preview_now. Reverting."
    exit 1
  fi

  # Prepare theme list for Rofi with icon paths (icon\ttext)
  rofi_input_list=""
  for theme_name_in_list in "${available_theme_names[@]}"; do
    local preview_path="$PREVIEW_DIR/${theme_name_in_list}.png"
    local display_name
    display_name=$(basename "$theme_name_in_list" .rasi)
    rofi_input_list+="${display_name}\ticon\t${preview_path}\n"
  done
  rofi_input_list_trimmed="${rofi_input_list%\\n}"

  # Launch Rofi and get user's choice
  chosen_index_from_rofi=$(echo -e "$rofi_input_list_trimmed" |
    rofi -dmenu -i \
      -format 'i' \
      -p "Rofi Theme" \
      -mesg "Enter: Preview  |  Ctrl+S: Apply  |  Esc: Cancel" \
      -config "$ROFI_THEME_FOR_THIS_SCRIPT" \
      -selected-row "$current_selection_index" \
      -kb-custom-1 "Control+s" \
      -show-icons)

  rofi_exit_code=$

  # Handle Rofi's exit code
  if [[ $rofi_exit_code -eq 0 ]]; then # Enter
    if [[ "$chosen_index_from_rofi" =~ ^[0-9]+$ ]] && [[ "$chosen_index_from_rofi" -lt "${#available_theme_names[@]}" ]]; then
      current_selection_index="$chosen_index_from_rofi"
    fi
  elif [[ $rofi_exit_code -eq 1 ]]; then # Escape
    notify_user "dialog-information" "Rofi Theme" "Selection cancelled. Reverting to original theme."
    echo "$original_rofi_config_content_backup" > "$ROFI_CONFIG_FILE"
    break
  elif [[ $rofi_exit_code -eq 10 ]]; then # Custom bind 1 (Ctrl+S)
    notify_user "dialog-apply" "Rofi Theme Applied" "$(basename "$theme_to_preview_now" .rasi)"
    break
  else # Error or unexpected exit code
    notify_user "dialog-error" "Rofi Error" "Unexpected Rofi exit ($rofi_exit_code). Reverting."
    echo "$original_rofi_config_content_backup" > "$ROFI_CONFIG_FILE"
    break
  fi
done

exit 0
