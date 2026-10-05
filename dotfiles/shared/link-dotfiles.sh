#!/usr/bin/env bash
# Symlink config files from this repo into $HOME. Safe to re-run; existing
# files that aren't already our symlinks are moved aside to <name>.bak.<timestamp>.
set -euo pipefail

SHARED="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$SHARED/../.." && pwd)"
STAMP="$(date +%Y%m%d%H%M%S)"

link() {
  local src="$1" dest="$2"

  if [[ -L "$dest" && "$(readlink "$dest")" == "$src" ]]; then
    echo "==> ok: $dest"
    return
  fi

  mkdir -p "$(dirname "$dest")"
  if [[ -e "$dest" || -L "$dest" ]]; then
    echo "==> backing up $dest -> $dest.bak.$STAMP"
    mv "$dest" "$dest.bak.$STAMP"
  fi

  ln -s "$src" "$dest"
  echo "==> linked: $dest -> $src"
}

# shell / editors
link "$SHARED/zsh/.zshrc"          "$HOME/.zshrc"
link "$REPO/vim/.vimrc"            "$HOME/.vimrc"

# git aliases, included from the (untracked) ~/.gitconfig so user/email stay local
link "$REPO/git/.gitconfig.aliases" "$HOME/.gitconfig.aliases"
if ! git config --global --get-all include.path | grep -qx '~/.gitconfig.aliases'; then
  git config --global --add include.path '~/.gitconfig.aliases'
  echo "==> added ~/.gitconfig.aliases to ~/.gitconfig includes"
fi

# ghostty: linux has its own config (alt keybinds); config/ghostty is macOS
if [[ "$(uname -s)" == Linux ]]; then
  link "$REPO/dotfiles/linux/ghostty/config" "$HOME/.config/ghostty/config"
  # cortile tiling (linux only; aerospace is the macOS counterpart)
  link "$REPO/dotfiles/linux/cortile/config.toml"   "$HOME/.config/cortile/config.toml"
  link "$REPO/dotfiles/linux/cortile/focus-direction.py" "$HOME/.config/cortile/focus-direction.py"
  link "$REPO/dotfiles/linux/cortile/zoom-toggle.sh" "$HOME/.config/cortile/zoom-toggle.sh"
  link "$REPO/dotfiles/linux/cortile/tiling-toggle.sh" "$HOME/.config/cortile/tiling-toggle.sh"
  # xremap: super acts as cmd in apps (super+t -> ctrl+t), started by external/xremap.sh
  link "$REPO/dotfiles/linux/xremap/config.yml" "$HOME/.config/xremap/config.yml"
  # ulauncher wrapper: picking an open app switches to it (started by external/ulauncher.sh)
  link "$REPO/dotfiles/linux/ulauncher/ulauncher-raise.py" "$HOME/.local/bin/ulauncher-raise"
  # super+q quits the focused app (bound in cinnamon.sh)
  link "$REPO/dotfiles/linux/scripts/quit-app.py" "$HOME/.local/bin/quit-app"
  link "$REPO/dotfiles/linux/scripts/focus-app.py" "$HOME/.local/bin/focus-app"
  link "$REPO/dotfiles/linux/scripts/power-mode.sh" "$HOME/.local/bin/power-mode"
  link "$REPO/dotfiles/linux/scripts/power-mode.desktop" "$HOME/.local/share/applications/power-mode.desktop"
  link "$REPO/dotfiles/linux/scripts/power-mode-tray.py" "$HOME/.local/bin/power-mode-tray"
  link "$REPO/dotfiles/linux/scripts/power-mode-tray.desktop" "$HOME/.config/autostart/power-mode-tray.desktop"
  # devilspie2: per-app window rules (spotify without a title bar), started by external/devilspie2.sh
  link "$REPO/dotfiles/linux/devilspie2/spotify.lua" "$HOME/.config/devilspie2/spotify.lua"
else
  link "$REPO/config/ghostty/config" "$HOME/.config/ghostty/config"
fi

# mise global tools
link "$SHARED/mise.toml"           "$HOME/.config/mise/config.toml"
