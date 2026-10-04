#!/usr/bin/env bash
set -euo pipefail

# Cinnamon desktop preferences. Safe to re-run.

if ! command -v gsettings >/dev/null 2>&1 || ! gsettings list-keys org.cinnamon >/dev/null 2>&1; then
  echo "==> cinnamon not installed, skipping desktop settings"
  exit 0
fi

WALLPAPER_DIR="$HOME/Documents/desktop-backgrounds"

echo "==> wallpaper slideshow: $WALLPAPER_DIR"
mkdir -p "$WALLPAPER_DIR"
slideshow=org.cinnamon.desktop.background.slideshow
gsettings set $slideshow image-source "directory://$WALLPAPER_DIR"
gsettings set $slideshow delay 15
gsettings set $slideshow random-order true
gsettings set $slideshow slideshow-enabled true

echo "==> panel icon sizes (0 = scale to panel height)"
gsettings set org.cinnamon panel-zone-icon-sizes '[{"panelId": 1, "left": 0, "center": 0, "right": 24}]'

# Applet settings files only exist after the applet has loaded once (first login).
gwl_uuid=grouped-window-list@cinnamon.org
gwl_dir="$HOME/.config/cinnamon/spices/$gwl_uuid"
if compgen -G "$gwl_dir/*.json" >/dev/null; then
  echo "==> window list: disable count/notification badges"
  python3 - "$gwl_dir"/*.json <<'EOF'
import json, sys
for path in sys.argv[1:]:
    with open(path) as f:
        d = json.load(f)
    for key in ("enable-window-count-badges", "enable-notification-badges"):
        if key in d:
            d[key]["value"] = False
    with open(path, "w") as f:
        json.dump(d, f, indent=4)
EOF
  # applets don't watch their settings file; reload so the change shows now
  dbus-send --session --dest=org.Cinnamon /org/Cinnamon \
    org.Cinnamon.ReloadXlet string:"$gwl_uuid" string:'APPLET' 2>/dev/null || true
else
  echo "==> window list settings not created yet; log into Cinnamon once and re-run"
fi
