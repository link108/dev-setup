#!/usr/bin/env bash
set -euo pipefail

if command -v tailscale >/dev/null 2>&1; then
  echo "Tailscale already installed"
  exit 0
fi

# Mint reports its own codename; Tailscale's repo is keyed on the Ubuntu base.
. /etc/os-release
codename="${UBUNTU_CODENAME:-$VERSION_CODENAME}"

curl -fsSL "https://pkgs.tailscale.com/stable/ubuntu/${codename}.noarmor.gpg" \
  | sudo tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null
curl -fsSL "https://pkgs.tailscale.com/stable/ubuntu/${codename}.tailscale-keyring.list" \
  | sudo tee /etc/apt/sources.list.d/tailscale.list >/dev/null

sudo apt update
sudo apt install -y tailscale
