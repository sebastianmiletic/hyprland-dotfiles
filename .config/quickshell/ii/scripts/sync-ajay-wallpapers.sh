#!/usr/bin/env bash
set -euo pipefail

source_root="$HOME/.local/share/wallpaper-sources/hyprland_wallpapers"
target_root="$HOME/Pictures/wallpapers"

if [[ ! -d "$source_root/.git" ]]; then
    printf 'Wallpaper source repository is missing: %s\n' "$source_root" >&2
    exit 1
fi

mkdir -p "$target_root"
count=0
while IFS= read -r -d '' source_path; do
    relative_path="${source_path#"$source_root"/}"
    # FolderListModel is intentionally flat, so preserve the path in a safe,
    # unique display name and link to the original full-resolution image.
    gallery_name="Ajay-${relative_path//\//__}"
    ln -sfn "$source_path" "$target_root/$gallery_name"
    count=$((count + 1))
done < <(find "$source_root" -path "$source_root/.git" -prune -o -type f \
    \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \
       -o -iname '*.avif' -o -iname '*.bmp' -o -iname '*.svg' \) -print0)

printf 'Linked %d wallpapers into %s\n' "$count" "$target_root"
