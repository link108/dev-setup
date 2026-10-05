#!/usr/bin/env bash
set -euo pipefail

# Modifier keys for the NEBULA68B (VIA keyboard, shared with the linux box). Safe to re-run.
# On the Mac its caps arrives as left cmd, so swap left option/cmd: caps is option (aerospace's
# alt-* binds) and the key next to space is cmd. Right option/cmd swapped too, caps -> right option
# kept from the stock setup. Same as System Settings > Keyboard > Modifier Keys for that keyboard.

VENDOR=35176  # 0x8968
PRODUCT=21304 # 0x5338

# HID usage page 7 key codes, as macOS stores them
key() { echo $((0x700000000 + $1)); }
CAPS=$(key 0x39) LALT=$(key 0xE2) LCMD=$(key 0xE3) RALT=$(key 0xE6) RCMD=$(key 0xE7)

pairs=("$RCMD:$RALT" "$RALT:$RCMD" "$LALT:$LCMD" "$LCMD:$LALT" "$CAPS:$RALT")

echo "==> keyboard: NEBULA68B caps = option, left option/cmd swapped"
plist=() json=()
for p in "${pairs[@]}"; do
  src="${p%%:*}" dst="${p#*:}"
  plist+=("<dict><key>HIDKeyboardModifierMappingSrc</key><integer>$src</integer><key>HIDKeyboardModifierMappingDst</key><integer>$dst</integer></dict>")
  json+=("{\"HIDKeyboardModifierMappingSrc\":$src,\"HIDKeyboardModifierMappingDst\":$dst}")
done

# persisted (picked up at login / replug)
defaults -currentHost write -g "com.apple.keyboard.modifiermapping.$VENDOR-$PRODUCT-0" -array "${plist[@]}"

# live, if the keyboard is plugged in
IFS=,
hidutil property --matching "{\"VendorID\":$VENDOR,\"ProductID\":$PRODUCT}" \
  --set "{\"UserKeyMapping\":[${json[*]}]}" >/dev/null
