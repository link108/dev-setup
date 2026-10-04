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

echo "==> keybindings: free super+l for window focus (was Looking Glass)"
gsettings set org.cinnamon.desktop.keybindings looking-glass-keybinding "[]"

# Workspaces for cortile tiling: super+N switches, super+shift+N moves the window
# (aerospace alt-N / alt-shift-N; alt is ghostty's here).
echo "==> workspaces: 6, super+N switch, super+shift+N move window"
gsettings set org.cinnamon.desktop.wm.preferences num-workspaces 6
for n in 1 2 3 4 5 6; do
  gsettings set org.cinnamon.desktop.keybindings.wm switch-to-workspace-$n "['<Super>$n']"
  gsettings set org.cinnamon.desktop.keybindings.wm move-to-workspace-$n "['<Super><Shift>$n']"
done

# Directional focus for cortile (it only has next/previous): super+h/j/k/l
echo "==> keybindings: super+h/j/k/l focus window left/down/up/right, alt+enter take over screen"
focus="$HOME/.config/cortile/focus-direction.py"
custom=/org/cinnamon/desktop/keybindings/custom-keybindings
ids=()
for pair in h:left j:down k:up l:right; do
  key="${pair%%:*}" dir="${pair#*:}" id="focus-$dir"
  dconf write "$custom/$id/name" "'Focus window $dir'"
  dconf write "$custom/$id/command" "'$focus $dir'"
  dconf write "$custom/$id/binding" "['<Super>$key']"
  ids+=("'$id'")
done
# alt+enter: focused window takes over the screen and back, via cortile (app fullscreen fights the tiling)
dconf write "$custom/zoom-toggle/name" "'Toggle window takes over screen (cortile)'"
dconf write "$custom/zoom-toggle/command" "'$HOME/.config/cortile/zoom-toggle.sh'"
dconf write "$custom/zoom-toggle/binding" "['<Alt>Return']"
ids+=("'zoom-toggle'")

list="$(dconf read /org/cinnamon/desktop/keybindings/custom-list)"
list="$(python3 -c '
import ast, sys
cur = ast.literal_eval(sys.argv[1]) if sys.argv[1] else []
ours = [i.strip("\x27") for i in sys.argv[2:]]
print([i for i in cur if i not in ours] + ours)
' "${list#@as }" "${ids[@]}")"
dconf write /org/cinnamon/desktop/keybindings/custom-list "$list"

# macOS-style layout: thin menu bar on top, Plank dock at the bottom.
echo "==> panel: move to top, 32px"
gsettings set org.cinnamon panels-enabled "['1:0:top']"
gsettings set org.cinnamon panels-height "['1:32']"

if command -v plank >/dev/null 2>&1; then
  echo "==> panel: remove window list (plank replaces it)"
  applets="$(gsettings get org.cinnamon enabled-applets)"
  applets="$(python3 -c '
import ast, sys
print([a for a in ast.literal_eval(sys.argv[1]) if "grouped-window-list@" not in a])
' "$applets")"
  gsettings set org.cinnamon enabled-applets "$applets"

  echo "==> plank: bottom, centered, always visible"
  dock=net.launchpad.plank.dock.settings:/net/launchpad/plank/docks/dock1/
  gsettings set $dock position bottom
  gsettings set $dock alignment center
  gsettings set $dock hide-mode none
  gsettings set $dock icon-size 48
  gsettings set $dock zoom-enabled true
  gsettings set $dock zoom-percent 150

  mkdir -p "$HOME/.config/autostart"
  cat > "$HOME/.config/autostart/plank.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=Plank
Exec=plank
X-GNOME-Autostart-enabled=true
EOF
  pgrep -x plank >/dev/null || (setsid plank >/dev/null 2>&1 &)
else
  echo "==> plank not installed, keeping panel window list"
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
fi
