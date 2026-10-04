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

install_cortile() {
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
}

if [[ -x "$BIN" ]] && "$BIN" -v 2>&1 | grep -q "$latest"; then
  echo "Cortile $latest already installed"
else
  install_cortile
fi

# First workspace starts untiled (floating windows); super+shift+t flips it back.
# Cortile caches this per workspace, so it only needs setting once, over its dbus API.
[[ -n "${DISPLAY:-}" ]] || { echo "cortile: no X session, skipping first-workspace setting"; exit 0; }
name=com.github.leukipp.cortile
path=/com/github/leukipp/cortile
pgrep -x cortile >/dev/null || (setsid "$BIN" >/dev/null 2>&1 &)
for _ in $(seq 20); do
  busctl --user status "$name" >/dev/null 2>&1 && break
  sleep 0.5
done
busctl --user call "$name" "$path" "$name" ActionExecute sii disable 0 0 >/dev/null
echo "cortile: tiling off on the first workspace"
