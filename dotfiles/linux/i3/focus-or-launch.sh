#!/usr/bin/env bash
# Usage: focus-or-launch.sh <class-regex> <command...>
# Focus a window whose WM_CLASS matches (case-insensitive), otherwise run the command.
set -euo pipefail

class="$1"
shift

if ! i3-msg "[class=\"(?i)$class\"] focus" | grep -q '"success":true'; then
  exec "$@"
fi
