#!/usr/bin/env bash
set -euo pipefail

# Start hidden at login (hotkey defaults to Ctrl+Space).
mkdir -p "$HOME/.config/autostart"
cat > "$HOME/.config/autostart/ulauncher.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=Ulauncher
Exec=ulauncher --hide-window
X-GNOME-Autostart-enabled=true
EOF

if command -v ulauncher >/dev/null 2>&1; then
  echo "Ulauncher already installed"
  exit 0
fi

sudo add-apt-repository -y ppa:agornostal/ulauncher
sudo apt update
sudo apt install -y ulauncher
