#!/usr/bin/env bash
set -euo pipefail

if command -v ghostty >/dev/null 2>&1; then
  echo "Ghostty already installed"
  exit 0
fi

if apt-cache show ghostty >/dev/null 2>&1; then
  sudo apt install -y ghostty
  exit 0
fi

sudo add-apt-repository -y ppa:mkasberg/ghostty-ubuntu
sudo apt update
sudo apt install -y ghostty
