#!/usr/bin/env bash
set -euo pipefail

# Start hidden at login. Hotkey is super+space (cmd-space, like spotlight); cinnamon.sh frees it.
mkdir -p "$HOME/.config/autostart"
cat > "$HOME/.config/autostart/ulauncher.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=Ulauncher
Exec=ulauncher --hide-window
X-GNOME-Autostart-enabled=true
EOF

# settings.json only exists after ulauncher has run once; ulauncher reads it at startup.
settings="$HOME/.config/ulauncher/settings.json"
if [[ -f "$settings" ]]; then
  python3 - "$settings" <<'PY'
import json, sys
with open(sys.argv[1]) as f:
    d = json.load(f)
d["hotkey-show-app"] = "<Super>space"
with open(sys.argv[1], "w") as f:
    json.dump(d, f, indent=4)
PY
  if pgrep -x ulauncher >/dev/null; then
    pkill -x ulauncher
    (setsid ulauncher --hide-window >/dev/null 2>&1 &)
  fi
  echo "Ulauncher hotkey: super+space"
fi

if command -v ulauncher >/dev/null 2>&1; then
  echo "Ulauncher already installed"
  exit 0
fi

sudo add-apt-repository -y ppa:agornostal/ulauncher
sudo apt update
sudo apt install -y ulauncher
