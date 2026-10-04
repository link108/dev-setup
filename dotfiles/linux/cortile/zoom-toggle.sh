#!/usr/bin/env bash
# Toggle "take over the screen" on the current workspace (alt+enter, bound in cinnamon.sh).
#
# Switches cortile to its maximized layout (focused window fills the tiling area, panel and
# dock stay) and back to whatever layout was active before. App fullscreen (e.g. ghostty's
# own toggle) fights cortile: it sees a resize, retiles and strips the fullscreen state.
# Talks to cortile's dbus API directly; `cortile dbus ...` takes ~0.5s per call.
set -euo pipefail

name=com.github.leukipp.cortile
path=/com/github/leukipp/cortile
desktop="$(wmctrl -d | awk '$2 == "*" {print $1}')"
screen=0
state="${XDG_RUNTIME_DIR:-/tmp}/cortile-zoom-$desktop-$screen"

layout="$(busctl --user --json=short get-property "$name" "$path" "$name" Workspaces | jq -r \
  --arg ws "workspace-$desktop-$screen" '
  .data.Values.data[].data
  | select(.Name.data == $ws)
  | .Layouts.data[.Layout.data].data.Name.data')"

if [[ "$layout" == maximized ]]; then
  previous="$(cat "$state" 2>/dev/null || echo vertical-left)"
  rm -f "$state"
  action="layout_${previous//-/_}"
else
  echo "$layout" > "$state"
  action=layout_maximized
fi

busctl --user call "$name" "$path" "$name" ActionExecute sii "$action" "$desktop" "$screen" >/dev/null
