#!/usr/bin/env bash
set -euo pipefail

command -v jq >/dev/null || {
  echo "jq is required" >&2
  exit 1
}

extensions=(
  "user-theme@gnome-shell-extensions.gcampax.github.com"
  "dash-to-dock@micxgx.gmail.com"
  "light-style@gnome-shell-extensions.gcampax.github.com"
  "drive-menu@gnome-shell-extensions.gcampax.github.com"
  "apps-menu@gnome-shell-extensions.gcampax.github.com"
  "places-menu@gnome-shell-extensions.gcampax.github.com"
  "status-icons@gnome-shell-extensions.gcampax.github.com"
  "window-list@gnome-shell-extensions.gcampax.github.com"
)

shell_version="$(gnome-shell --version | sed -E 's/[^0-9]*([0-9]+).*/\1/')"
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

mapfile -t installed < <(gnome-extensions list)
is_installed() { printf '%s\n' "${installed[@]}" | grep -qx "$1"; }

for uuid in "${extensions[@]}"; do
  if is_installed "$uuid"; then
    echo "Already installed, skipping: $uuid"
  else
    echo "Searching: $uuid"
    name_part="${uuid%%@*}"
    search_term="${name_part//-/ }"
    pk="$(curl -fsSLG --data-urlencode "search=$search_term" \
      "https://extensions.gnome.org/extension-query/" |
      jq -r --arg uuid "$uuid" '.extensions[] | select(.uuid == $uuid) | .pk' | head -n1)"

    if [[ -z "$pk" || "$pk" == "null" ]]; then
      echo "Not found: $uuid"
      continue
    fi

    download_url="$(curl -fsSLG --data-urlencode "pk=$pk" --data-urlencode "shell_version=$shell_version" \
      "https://extensions.gnome.org/extension-info/" | jq -r '.download_url // empty')"

    if [[ -z "$download_url" ]]; then
      echo "No compatible version for GNOME $shell_version: $uuid"
      continue
    fi

    zipfile="$tmpdir/${pk}.zip"
    echo "Installing: $uuid"
    curl -fsSL "https://extensions.gnome.org${download_url}" -o "$zipfile"
    gnome-extensions install --force "$zipfile"
  fi

  gnome-extensions enable "$uuid" 2>/dev/null || echo "Failed to enable: $uuid"
done

echo
echo "Done. Current extension list:"
gnome-extensions list
