#!/usr/bin/env bash
set -euo pipefail

# xremap: super acts as cmd in apps (super+t -> ctrl+t outside ghostty). Config:
# dotfiles/linux/xremap/config.yml. Installs the X11 release binary to ~/.local/bin, lets the
# logged-in user read keyboards and write /dev/uinput (udev uaccess, no root daemon), starts at login.

BIN="$HOME/.local/bin/xremap"
CONFIG="$HOME/.config/xremap/config.yml"

mkdir -p "$HOME/.config/autostart"
cat > "$HOME/.config/autostart/xremap.desktop" <<DESKTOP
[Desktop Entry]
Type=Application
Name=xremap
Exec=$BIN --watch=device,config $CONFIG
X-GNOME-Autostart-enabled=true
DESKTOP

rule=/etc/udev/rules.d/70-xremap.rules
if [[ ! -f "$rule" ]]; then
  echo "==> xremap: udev rule for keyboard + uinput access (sudo)"
  sudo tee "$rule" >/dev/null <<'RULE'
KERNEL=="uinput", GROUP="input", MODE="0660", OPTIONS+="static_node=uinput", TAG+="uaccess"
SUBSYSTEM=="input", KERNEL=="event*", TAG+="uaccess"
RULE
  sudo modprobe uinput
  sudo udevadm control --reload-rules
  sudo udevadm trigger
fi

latest="$(curl -fsSL https://api.github.com/repos/xremap/xremap/releases/latest | jq -r .tag_name)"
if [[ -x "$BIN" ]] && "$BIN" --version 2>&1 | grep -q "${latest#v}"; then
  echo "xremap $latest already installed"
else
  case "$(uname -m)" in
    x86_64) arch=x86_64 ;;
    aarch64) arch=aarch64 ;;
    *) echo "xremap: unsupported arch $(uname -m)"; exit 1 ;;
  esac
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT
  curl -fsSL "https://github.com/xremap/xremap/releases/download/$latest/xremap-linux-$arch-x11.zip" -o "$tmp/xremap.zip"
  unzip -q "$tmp/xremap.zip" -d "$tmp"
  mkdir -p "$(dirname "$BIN")"
  install -m 755 "$tmp/xremap" "$BIN"
  echo "xremap $latest installed to $BIN"
fi

# (Re)start so a new binary or autostart flags apply; skip outside an X session.
if [[ -n "${DISPLAY:-}" && -f "$CONFIG" ]]; then
  pkill -x xremap || true
  (setsid "$BIN" --watch=device,config "$CONFIG" >/tmp/xremap.log 2>&1 &)
  echo "xremap: running (log /tmp/xremap.log)"
fi
