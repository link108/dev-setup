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

# OpenLinkHub only gets the CORE. The Commander PRO (0x0c10) stays with CoolerControl and the
# Lighting Node Pro (0x0c0b) keeps its hardware lighting.
config=/opt/OpenLinkHub/config.json
sudo systemctl stop OpenLinkHub.service
sudo jq '.exclude = [3088, 3083]' "$config" | sudo tee "$config.tmp" >/dev/null
sudo mv "$config.tmp" "$config"
sudo systemctl enable --now OpenLinkHub.service

# And CoolerControl stops talking to it. Disabling just the CORE device in CoolerControl still
# initializes it through liquidctl, which knocked it back to the hardware color loop, so liquidctl
# goes entirely: the Commander PRO falls back to its kernel driver (corsair-cpro), and the Lighting
# Node Pro and Aura controller only do lighting, which CoolerControl wasn't setting anyway.
cc_config=/etc/coolercontrol/config.toml
if [ -f "$cc_config" ] && grep -q '^liquidctl_integration = true' "$cc_config"; then
  sudo systemctl stop coolercontrold
  sudo sed -i 's/^liquidctl_integration = true/liquidctl_integration = false/' "$cc_config"
  sudo systemctl start coolercontrold
fi
