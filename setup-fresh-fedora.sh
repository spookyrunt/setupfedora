#!/bin/bash
set -euo pipefail

rpm-ostree install --idempotent gnome-tweaks \
  git xclip xsel wl-clipboard \
  ripgrep fd-find fzf \
  nodejs npm \
  podman-docker podman-compose \
  gpaste gpaste-ui gnome-shell-extension-gpaste \
  trash-cli

flatpak uninstall -y \
  org.gnome.Weather \
  org.gnome.Calendar \
  org.gnome.Contacts \
  org.gnome.TextEditor

flatpak install org.gnome.extensions \
  org.gnome.gedit \
  net.nokyan.Resources \
  org.gnome.seahorse.Application

# export cargo bin
if ! grep -q 'export PATH="$PATH:$HOME/.cargo/bin"' ~/.bash_profile 2>/dev/null; then
  printf '\nexport PATH="$PATH:$HOME/.cargo/bin"' >>~/.bash_profile
fi

# export go bin
if ! grep -q 'export PATH="$PATH:$HOME/go/bin"' ~/.bash_profile 2>/dev/null; then
  printf '\nexport PATH="$PATH:$HOME/go/bin"' >>~/.bash_profile
fi

./setup-nvim.sh
./setup-gshell.sh
./setup-gcm.sh

if [ -z "$(ls -A ~/.local/share/themes/Yaru-light/ 2>/dev/null)" ]; then
  mkdir -p ~/.local/share/themes/Yaru-light/
  curl -sL $(curl -s https://api.github.com/repos/spookyrunt/Yaru-light/releases/latest |
    jq -r '.assets[0].browser_download_url') |
    tar -xzv -C ~/.local/share/themes/Yaru-light/ --strip-components=1
fi

gsettings set org.gnome.shell.extensions.user-theme name "Yaru-light"
gsettings set org.gnome.desktop.interface text-scaling-factor 1.10
gsettings set org.gnome.SessionManager logout-prompt false
gsettings set org.gnome.shell.extensions.dash-to-dock dock-position 'RIGHT'
gsettings set org.gnome.shell.extensions.dash-to-dock custom-theme-shrink true
gsettings set org.gnome.shell.extensions.dash-to-dock dock-fixed true
gsettings set org.gnome.shell.extensions.dash-to-dock extend-height true
gsettings set org.gnome.shell.extensions.dash-to-dock disable-overview-on-startup true
gsettings set org.gnome.mutter attach-modal-dialogs false

echo ""
echo "Finished. Please reboot."
