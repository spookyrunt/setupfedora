#!/bin/bash
set -euo pipefail

sudo firewall-cmd --set-default-zone=drop
sudo firewall-cmd --permanent --zone=trusted --add-source=192.168.0.0/24
sudo firewall-cmd --reload
