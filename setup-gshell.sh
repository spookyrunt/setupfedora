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

# Download and install
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT
shell_api="$(gnome-shell --version | grep -oE '[0-9]+(\.[0-9]+)+' | cut -d. -f1)"
for uuid in "${extensions[@]}"; do
  printf 'Installing %s...\n' "$uuid"
  if curl -fsSL --retry 2 \
    "https://extensions.gnome.org/download-extension/${uuid}.shell-extension.zip?shell_version=${shell_api}" \
    -o "$tmpdir/${uuid}.zip"; then
    gnome-extensions install --force "$tmpdir/${uuid}.zip" || printf 'Install failed: %s\n' "$uuid"
  else
    printf 'Download failed or unsupported: %s\n' "$uuid"
  fi
done

# Enable or disable
python3 - "${extensions[@]}" <<'PY'
import ast, subprocess, sys
raw = subprocess.check_output(
    ["gsettings", "get", "org.gnome.shell", "enabled-extensions"],
    text=True,
).strip()
current = ast.literal_eval(raw.removeprefix("@as "))
current += ["GPaste@gnome-shell-extensions.gnome.org"]
value = repr(list(dict.fromkeys(current + sys.argv[1:])))
subprocess.run([
    "gsettings", "set", "org.gnome.shell", "enabled-extensions", value
], check=True)
print(value)
PY

# Yaru-light
if [ -z "$(ls -A ~/.local/share/themes/Yaru-light/ 2>/dev/null)" ]; then
  mkdir -p ~/.local/share/themes/Yaru-light/
  curl -sL $(curl -s https://api.github.com/repos/spookyrunt/Yaru-light/releases/latest |
    jq -r '.assets[0].browser_download_url') |
    tar -xzv -C ~/.local/share/themes/Yaru-light/ --strip-components=1
fi

# gsettings
gsettings set org.gnome.shell.extensions.user-theme name "Yaru-light"
gsettings set org.gnome.desktop.interface text-scaling-factor 1.10
gsettings set org.gnome.SessionManager logout-prompt false
GSETTINGS_SCHEMA_DIR="$HOME/.local/share/gnome-shell/extensions/dash-to-dock@micxgx.gmail.com/schemas" \
  gsettings set org.gnome.shell.extensions.dash-to-dock dock-position 'RIGHT'
GSETTINGS_SCHEMA_DIR="$HOME/.local/share/gnome-shell/extensions/dash-to-dock@micxgx.gmail.com/schemas" \
  gsettings set org.gnome.shell.extensions.dash-to-dock custom-theme-shrink true
GSETTINGS_SCHEMA_DIR="$HOME/.local/share/gnome-shell/extensions/dash-to-dock@micxgx.gmail.com/schemas" \
  gsettings set org.gnome.shell.extensions.dash-to-dock dock-fixed true
GSETTINGS_SCHEMA_DIR="$HOME/.local/share/gnome-shell/extensions/dash-to-dock@micxgx.gmail.com/schemas" \
  gsettings set org.gnome.shell.extensions.dash-to-dock extend-height true
GSETTINGS_SCHEMA_DIR="$HOME/.local/share/gnome-shell/extensions/dash-to-dock@micxgx.gmail.com/schemas" \
  gsettings set org.gnome.shell.extensions.dash-to-dock disable-overview-on-startup true
gsettings set org.gnome.mutter attach-modal-dialogs false
gsettings set org.gnome.desktop.screensaver lock-enabled false
gsettings set org.gnome.desktop.screensaver lock-delay 0
gsettings set org.gnome.desktop.session idle-delay 900

echo
echo "Done. Current extension list:"
gnome-extensions list
