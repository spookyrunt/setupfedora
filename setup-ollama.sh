#!/bin/bash
set -euo pipefail

is_btrfs() {
  [ "$(stat -f -c %T "$1" 2>/dev/null)" = "btrfs" ]
}

SYSTEM_DIR="/usr/share/ollama"
USER_DIR="$HOME/.ollama"

echo "Starting pre-installation Btrfs NOCOW configuration..."
mkdir -p "$USER_DIR"
if is_btrfs "$USER_DIR"; then
  chattr -R +C "$USER_DIR"
  echo "[OK] NOCOW applied: $USER_DIR"
else
  echo "[INFO] $USER_DIR not on Btrfs, skipping"
fi

echo "Pre-configuration complete. Running the official Ollama installer..."
curl -fsSL https://ollama.com/install.sh | sh

RAM=$(free -m | awk '/^Mem:/{print $2}')
sudo tee /etc/systemd/system/ollama.service <<EOF
[Unit]
Description=Ollama Service
After=network-online.target

[Service]
ExecStart=/usr/local/bin/ollama serve
User=$USER
Group=$USER
Restart=always
RestartSec=3
Environment="PATH=$PATH"
Environment=OLLAMA_HOST=0.0.0.0:11434
Environment=OLLAMA_IGPU_ENABLE=1
Environment=OLLAMA_KEEP_ALIVE=30m
Environment=OLLAMA_MAX_LOADED_MODELS=1
Environment=OLLAMA_FLASH_ATTENTION=1
Environment=OLLAMA_GPU_OVERHEAD=0
Environment=OLLAMA_CONTEXT_LENGTH=$(($RAM * 4))
Environment=OLLAMA_MAX_QUEUE=4
OOMScoreAdjust=-900
Environment=OLLAMA_KV_CACHE_TYPE=q4_0

[Install]
WantedBy=multi-user.target
EOF

echo ""
echo "Finished installing Ollama."
