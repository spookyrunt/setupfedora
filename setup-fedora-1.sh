#!/bin/bash
set -euo pipefail

rpm-ostree install -y --idempotent gnome-tweaks \
  git xclip xsel \
  ripgrep fd-find fzf \
  nodejs npm \
  podman-docker podman-compose \
  gpaste gpaste-ui gnome-shell-extension-gpaste dconf-editor \
  trash-cli earlyoom gparted

echo ""
echo "Done. Please reboot."
