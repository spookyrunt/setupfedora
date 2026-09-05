#!/bin/bash
set -euo pipefail

# 1. Fetch the latest GCM tar.gz asset URL (exclude the -symbols.tar.gz debug package)
GCM_URL="$(
  curl -fsSL https://api.github.com/repos/git-ecosystem/git-credential-manager/releases/latest |
    jq -r '
      .assets[]
      | select(.name | test("^gcm-linux-x64-.*\\.tar\\.gz$"))
      | select(.name | contains("-symbols.") | not)
      | .browser_download_url
    ' |
    head -n 1
)"
if [[ -z "$GCM_URL" || "$GCM_URL" == "null" ]]; then
  echo "Error: Failed to fetch the GCM download URL."
  exit 1
fi

# 2. Download and extract into /usr/local/bin
curl -fL "$GCM_URL" -o gcm-linux-x64.tar.gz
sudo mkdir -p /usr/local/bin
sudo tar -xzf gcm-linux-x64.tar.gz -C /usr/local/bin
sudo chmod +x /usr/local/bin/git-credential-manager

# 3. Configure Git Credential Manager
git-credential-manager configure
# git config --global credential.credentialStore cache
git config --global credential.credentialStore secretservice
git config --global core.editor "nvim"

# 4. Clean up the downloaded file
rm gcm-linux-x64.tar.gz
