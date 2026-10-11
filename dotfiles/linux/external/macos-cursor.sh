#!/usr/bin/env bash
set -euo pipefail

# macOS cursors (ful1e5/apple_cursor): arrow, link hand, text beam, resize arrows, busy spinner.
# Installs the latest release to ~/.local/share/icons/macOS; cinnamon.sh selects it.

DIR="$HOME/.local/share/icons"
THEME=macOS

latest="$(curl -fsSL https://api.github.com/repos/ful1e5/apple_cursor/releases/latest | jq -r .tag_name)"
stamp="$DIR/$THEME/.version"

if [[ -f "$stamp" && "$(cat "$stamp")" == "$latest" ]]; then
  echo "macOS cursors $latest already installed"
else
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT
  curl -fsSL "https://github.com/ful1e5/apple_cursor/releases/download/$latest/$THEME.tar.xz" -o "$tmp/cursor.tar.xz"
  tar -xJf "$tmp/cursor.tar.xz" -C "$tmp"
  mkdir -p "$DIR"
  rm -rf "${DIR:?}/$THEME"
  mv "$tmp/$THEME" "$DIR/$THEME"
  echo "$latest" > "$stamp"
  echo "macOS cursors $latest installed to $DIR/$THEME"
fi

# fallback for X apps that don't read the desktop's cursor setting (the system default is Bibata)
mkdir -p "$HOME/.icons/default"
cat > "$HOME/.icons/default/index.theme" <<EOF
[Icon Theme]
Inherits=$THEME
EOF
