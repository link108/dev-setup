#!/usr/bin/env bash
# Service mode actions (alt+shift+; then a key, see xremap/config.yml), cortile's take on
# aerospace's service mode. Cortile has no container tree to join-with, so alt+shift+h/j/k/l
# instead makes the focused window the main tile on that side of the screen; r resets the
# workspace to the default layout and proportions (aerospace's flatten-workspace-tree).
set -euo pipefail

# xremap starts without the session's dbus address; busctl --user finds the bus from this
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"

name=com.github.leukipp.cortile
path=/com/github/leukipp/cortile
desktop="$(wmctrl -d | awk '$2 == "*" {print $1}')"

cortile() {
  busctl --user call "$name" "$path" "$name" ActionExecute sii "$1" "$desktop" 0 >/dev/null
}

# each layout keeps its own window order, so switch layout before picking the master
case "${1:-}" in
  left)  cortile layout_vertical_left;      cortile master_make ;;
  right) cortile layout_vertical_right;     cortile master_make ;;
  up)    cortile layout_horizontal_top;     cortile master_make ;;
  down)  cortile layout_horizontal_bottom;  cortile master_make ;;
  reset) cortile layout_vertical_left;      cortile reset ;;
  *) echo "usage: retile.sh left|down|up|right|reset" >&2; exit 1 ;;
esac
