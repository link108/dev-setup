#!/usr/bin/env bash
set -euo pipefail

# Cortile: auto-tiling on top of Cinnamon (X11). Config: dotfiles/linux/cortile/config.toml
# Installs the latest release binary to ~/.local/bin and starts it at login.

BIN="$HOME/.local/bin/cortile"

mkdir -p "$HOME/.config/autostart"
cat > "$HOME/.config/autostart/cortile.desktop" <<'DESKTOP'
[Desktop Entry]
Type=Application
Name=Cortile
Exec=sh -c '"$HOME/.local/bin/cortile"'
X-GNOME-Autostart-enabled=true
DESKTOP

latest="$(curl -fsSL https://api.github.com/repos/leukipp/cortile/releases/latest | jq -r .tag_name)"
latest="${latest#v}"

if [[ -x "$BIN" ]] && "$BIN" -v 2>&1 | grep -q "$latest"; then
  echo "Cortile $latest already installed"
  exit 0
fi

case "$(uname -m)" in
  x86_64) arch=amd64 ;;
  aarch64) arch=arm64 ;;
  *) echo "cortile: unsupported arch $(uname -m)"; exit 1 ;;
esac

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
url="https://github.com/leukipp/cortile/releases/download/v$latest/cortile_${latest}_linux_${arch}.tar.gz"
curl -fsSL "$url" -o "$tmp/cortile.tar.gz"
tar -xzf "$tmp/cortile.tar.gz" -C "$tmp"
mkdir -p "$(dirname "$BIN")"
install -m 755 "$tmp/cortile" "$BIN"
echo "Cortile $latest installed to $BIN"
