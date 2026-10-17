#!/usr/bin/env bash
set -euo pipefail

# Switching the KVM away unplugs the monitor, so X shrinks the screen and squashes every window to
# fit; switching back leaves them that size. Pin each connected nvidia output as always connected,
# with its EDID saved to disk, so the driver keeps the screen at full size while the KVM is away.
# Takes effect after logging out (or a reboot). Undo: sudo rm /etc/X11/xorg.conf.d/20-nvidia-kvm.conf

CONF=/etc/X11/xorg.conf.d/20-nvidia-kvm.conf
EDID_DIR=/etc/X11/edid

if ! command -v nvidia-smi >/dev/null 2>&1 || [[ -z "${DISPLAY:-}" ]]; then
  echo "no nvidia gpu or no X display; skipping"
  exit 0
fi

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# xrandr --props prints each connected output's EDID as hex lines under "EDID:"
xrandr --props | awk -v dir="$tmp" '
  / connected/ { out = $1 }
  /^\t[A-Za-z]/ { inedid = ($1 == "EDID:") ; next }
  inedid && /^\t\t[0-9a-f]+$/ { gsub(/\t/, ""); printf "%s", $0 > (dir "/" out ".hex") }
'

outputs=()
for hex in "$tmp"/*.hex; do
  [[ -e "$hex" ]] || continue
  out="$(basename "$hex" .hex)"
  xxd -r -p "$hex" > "$tmp/$out.bin"
  outputs+=("$out")
done

if [[ ${#outputs[@]} -eq 0 ]]; then
  echo "no connected monitors with an EDID (is the KVM switched to this machine?); skipping"
  exit 0
fi

connected="$(IFS=,; echo "${outputs[*]}")"
edids="$(for o in "${outputs[@]}"; do printf '%s:%s/%s.bin;' "$o" "$EDID_DIR" "$o"; done)"
edids="${edids%;}"

cat > "$tmp/conf" <<EOF
# Written by dev-setup dotfiles/linux/external/kvm-monitor.sh
Section "Device"
    Identifier "nvidia"
    Driver     "nvidia"
    Option     "ConnectedMonitor" "$connected"
    Option     "CustomEDID"       "$edids"
    Option     "UseHotplugEvents" "false"
EndSection
EOF

up_to_date=true
cmp -s "$tmp/conf" "$CONF" || up_to_date=false
for o in "${outputs[@]}"; do
  cmp -s "$tmp/$o.bin" "$EDID_DIR/$o.bin" || up_to_date=false
done

if $up_to_date; then
  echo "monitors pinned for the KVM: $connected (already configured)"
else
  sudo install -d "$EDID_DIR" "$(dirname "$CONF")"
  for o in "${outputs[@]}"; do sudo install -m 644 "$tmp/$o.bin" "$EDID_DIR/$o.bin"; done
  sudo install -m 644 "$tmp/conf" "$CONF"
  echo "monitors pinned for the KVM: $connected (log out and back in to apply)"
fi
