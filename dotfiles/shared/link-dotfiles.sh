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

# ghostty: linux has its own config (super keybinds, Cinnamon conflicts); config/ghostty is macOS
if [[ "$(uname -s)" == Linux ]]; then
  link "$REPO/dotfiles/linux/ghostty/config" "$HOME/.config/ghostty/config"
else
  link "$REPO/config/ghostty/config" "$HOME/.config/ghostty/config"
fi

# mise global tools
link "$SHARED/mise.toml"           "$HOME/.config/mise/config.toml"
