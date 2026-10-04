#!/usr/bin/env bash
set -euo pipefail

# devilspie2 applies per-app window rules as windows open (dotfiles/linux/devilspie2/*.lua, linked
# to ~/.config/devilspie2 by link-dotfiles.sh). Installed from apt.txt; this starts it at login.

mkdir -p "$HOME/.config/autostart"
cat > "$HOME/.config/autostart/devilspie2.desktop" <<'DESKTOP'
[Desktop Entry]
Type=Application
Name=devilspie2
Exec=devilspie2
X-GNOME-Autostart-enabled=true
DESKTOP

if [[ -n "${DISPLAY:-}" ]] && command -v devilspie2 >/dev/null 2>&1; then
  pkill -x devilspie2 || true
  (setsid devilspie2 >/dev/null 2>&1 &)
  echo "devilspie2: running"
fi
