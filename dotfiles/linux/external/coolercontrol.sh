#!/usr/bin/env bash
set -euo pipefail

# Temperatures, fans and pump in one place: CPU (k10temp), board (asusec), RTX 3080 (nvidia),
# Corsair Commander PRO (kernel driver) and Commander CORE AIO (no kernel driver, read through
# liquidctl). The daemon serves the UI at http://localhost:11987; the coolercontrol app wraps it.
if command -v coolercontrold >/dev/null 2>&1; then
  echo "CoolerControl already installed"
  exit 0
fi

# What https://apt.coolercontrol.org/setup.sh does, without piping it to sudo sh. Mint is
# Ubuntu based, so the ubuntu tree.
keyring=/usr/share/keyrings/coolercontrol-archive-keyring.gpg
curl -fsSL https://apt.coolercontrol.org/coolercontrol-archive-keyring.gpg | sudo tee "$keyring" >/dev/null
sudo tee /etc/apt/sources.list.d/coolercontrol.sources >/dev/null <<EOF
Types: deb
URIs: https://apt.coolercontrol.org/ubuntu
Suites: stable
Components: main
Signed-By: $keyring
EOF

sudo apt update
sudo apt install -y coolercontrol liquidctl
sudo systemctl enable --now coolercontrold
