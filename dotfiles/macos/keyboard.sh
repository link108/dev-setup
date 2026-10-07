#!/usr/bin/env bash
set -euo pipefail

# Modifier keys for the NEBULA68B (VIA keyboard, shared with the linux box). Safe to re-run.
# On the Mac its caps arrives as left cmd, so swap left option/cmd: caps is option (aerospace's
# alt-* binds) and the key next to space is cmd. The right key next to space already arrives as cmd, caps -> right option
# kept from the stock setup. Same as System Settings > Keyboard > Modifier Keys for that keyboard.
#
# macOS drops the remap when the keyboard reconnects (switching it to the linux box and back), so
# this also installs a LaunchAgent that runs `keyboard.sh --watch` and re-applies it.

VENDOR=35176  # 0x8968
PRODUCT=21304 # 0x5338
MATCH="{\"VendorID\":$VENDOR,\"ProductID\":$PRODUCT}"
LABEL=com.link108.keyboard-remap

# HID usage page 7 key codes, as macOS stores them
key() { echo $((0x700000000 + $1)); }
CAPS=$(key 0x39) LALT=$(key 0xE2) LCMD=$(key 0xE3) RALT=$(key 0xE6) RCMD=$(key 0xE7)

pairs=("$LALT:$LCMD" "$LCMD:$LALT" "$CAPS:$RALT")

plist=() json=()
for p in "${pairs[@]}"; do
  src="${p%%:*}" dst="${p#*:}"
  plist+=("<dict><key>HIDKeyboardModifierMappingSrc</key><integer>$src</integer><key>HIDKeyboardModifierMappingDst</key><integer>$dst</integer></dict>")
  json+=("{\"HIDKeyboardModifierMappingSrc\":$src,\"HIDKeyboardModifierMappingDst\":$dst}")
done
mapping="{\"UserKeyMapping\":[$(IFS=,; echo "${json[*]}")]}"

apply_live() { hidutil property --matching "$MATCH" --set "$mapping" >/dev/null; }

if [[ ${1:-} == --watch ]]; then
  # one row per HID service of the keyboard; re-apply when any of them lacks the caps remap
  # (a freshly connected keyboard shows (null)). An absent keyboard has no rows, so it's left alone.
  while true; do
    out="$(hidutil property --matching "$MATCH" --get UserKeyMapping 2>/dev/null || true)"
    services="$(grep -cE '^[0-9a-f]+ +UserKeyMapping' <<<"$out" || true)"
    mapped="$(grep -c "MappingSrc = $CAPS;" <<<"$out" || true)"
    if (( services > 0 && mapped < services )); then
      apply_live
    fi
    sleep 3
  done
fi

echo "==> keyboard: NEBULA68B caps = option, left option/cmd swapped"
defaults -currentHost write -g "com.apple.keyboard.modifiermapping.$VENDOR-$PRODUCT-0" -array "${plist[@]}"
apply_live

echo "==> keyboard: LaunchAgent re-applies the remap when the keyboard reconnects"
script="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
agent="$HOME/Library/LaunchAgents/$LABEL.plist"
mkdir -p "$(dirname "$agent")"
cat > "$agent" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>$LABEL</string>
  <key>ProgramArguments</key><array><string>/bin/bash</string><string>$script</string><string>--watch</string></array>
  <key>RunAtLoad</key><true/>
  <key>KeepAlive</key><true/>
  <key>ProcessType</key><string>Background</string>
</dict>
</plist>
EOF
launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$agent"
