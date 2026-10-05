#!/usr/bin/env bash
set -euo pipefail

# Corsair Commander CORE (AIO pump, pump-head RGB and its fans). liquidctl, which CoolerControl
# uses, has no RGB for it and drops it in and out of software mode on every poll, so the
# hardware color loop kept going dark and restarting. OpenLinkHub holds it in software mode and
# drives the lighting itself. Web UI at http://127.0.0.1:27003.
if ! command -v OpenLinkHub >/dev/null 2>&1 && [ ! -x /opt/OpenLinkHub/OpenLinkHub ]; then
  # Mint's add-apt-repository maps to the Ubuntu base (noble), which the PPA builds for.
  sudo add-apt-repository -y ppa:jurkovic-nikola/openlinkhub
  sudo apt update
  sudo apt install -y openlinkhub
fi

# OpenLinkHub only gets the CORE. The Commander PRO (0x0c10) and Lighting Node Pro (0x0c0b)
# stay with CoolerControl, so nothing has two programs talking to it.
config=/opt/OpenLinkHub/config.json
sudo systemctl stop OpenLinkHub.service
sudo jq '.exclude = [3088, 3083]' "$config" | sudo tee "$config.tmp" >/dev/null
sudo mv "$config.tmp" "$config"
sudo systemctl enable --now OpenLinkHub.service

# And CoolerControl stops polling the CORE. Its UID is a hash generated on this machine, so
# look it up by name; the daemon must be stopped while the file is edited.
cc_config=/etc/coolercontrol/config.toml
if [ -f "$cc_config" ]; then
  uid=$(grep -oP '^[0-9a-f]{64}(?= = "Corsair Commander Core)' "$cc_config" || true)
  if [ -n "$uid" ] && ! grep -q "^\[settings\.$uid\]" "$cc_config"; then
    sudo systemctl stop coolercontrold
    printf '\n[settings.%s]\ndisabled = true\n' "$uid" | sudo tee -a "$cc_config" >/dev/null
    sudo systemctl start coolercontrold
  fi
fi
