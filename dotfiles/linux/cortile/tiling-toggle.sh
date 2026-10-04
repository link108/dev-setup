#!/usr/bin/env bash
# Toggle tiling on/off for the current workspace (super+shift+t, bound in cinnamon.sh).
# Bound through Cinnamon because cortile's own grab of the key never fired.
set -euo pipefail

name=com.github.leukipp.cortile
path=/com/github/leukipp/cortile
desktop="$(wmctrl -d | awk '$2 == "*" {print $1}')"

busctl --user call "$name" "$path" "$name" ActionExecute sii toggle "$desktop" 0 >/dev/null
