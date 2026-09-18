#!/bin/bash
set -euo pipefail

flatpak uninstall --system -y \
  org.gnome.Weather \
  org.gnome.Calendar \
  org.gnome.Contacts \
  org.gnome.TextEditor || true

flatpak install -y org.gnome.Extensions \
  org.gnome.gedit \
  net.nokyan.Resources \
  org.gnome.seahorse.Application || true

# turn on ssh
sudo systemctl enable --now sshd.service

# setup ll
grep -qxF "alias ll='ls -alF'" ~/.bashrc || echo "alias ll='ls -alF'" >>~/.bashrc

# hangul IME
ibus restart
gsettings set org.gnome.desktop.input-sources sources "[('ibus', 'hangul')]"

# rpm-ostree install
sudo systemctl enable earlyoom

# export cargo bin
if ! grep -q 'export PATH="$HOME/.cargo/bin:$PATH"' ~/.bash_profile 2>/dev/null; then
  printf '\nexport PATH="$HOME/.cargo/bin:$PATH"' >>~/.bash_profile
fi

# export go bin
if ! grep -q 'export PATH="$HOME/go/bin:$PATH"' ~/.bash_profile 2>/dev/null; then
  printf '\nexport PATH="$HOME/go/bin:$PATH"' >>~/.bash_profile
fi

./setup-nvim.sh
./setup-gshell.sh
./setup-gcm.sh

echo ""
echo "Finished."
