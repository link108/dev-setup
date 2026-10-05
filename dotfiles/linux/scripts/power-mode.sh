#!/usr/bin/env bash
# Toggle low power mode: power-profiles-daemon's power-saver <-> balanced. The Cinnamon power
# applet has this switch but hides itself on a desktop (no battery or backlight).
#
#   power-mode            toggle
#   power-mode <profile>  set power-saver, balanced or performance
#
# On the 5900X (amd-pstate-epp) power-saver sets the energy preference to "power", so cores clock
# down and boost less. Games launched through gamemoderun still get performance while they run.
set -euo pipefail

if [[ $# -gt 0 ]]; then
  next=$1
elif [[ "$(powerprofilesctl get)" == power-saver ]]; then
  next=balanced
else
  next=power-saver
fi
powerprofilesctl set "$next"

case $next in
  power-saver) msg="Low power mode on" icon=power-profile-power-saver-symbolic ;;
  balanced) msg="Low power mode off" icon=power-profile-balanced-symbolic ;;
  *) msg="Power mode: $next" icon=power-profile-performance-symbolic ;;
esac
notify-send -i "$icon" -h string:x-canonical-private-synchronous:power-mode "$msg"
echo "$msg"
