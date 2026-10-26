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
  link "$REPO/dotfiles/linux/ghostty/tabs.css" "$HOME/.config/ghostty/tabs.css"
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
  # tailscale devices and exit nodes in the panel (operator set by external/tailscale.sh)
  link "$REPO/dotfiles/linux/scripts/tailscale-tray.py" "$HOME/.local/bin/tailscale-tray"
  link "$REPO/dotfiles/linux/scripts/tailscale-tray.desktop" "$HOME/.config/autostart/tailscale-tray.desktop"
  # wine/proton windows don't steal focus when switching back to their workspace
  link "$REPO/dotfiles/linux/scripts/keep-focus.py" "$HOME/.local/bin/keep-focus"
  link "$REPO/dotfiles/linux/scripts/keep-focus.desktop" "$HOME/.config/autostart/keep-focus.desktop"
  # panel applet: cpu/mem/gpu usage and temps (added to the panel by cinnamon.sh)
  link "$REPO/dotfiles/linux/cinnamon/sysmon@link108" "$HOME/.local/share/cinnamon/applets/sysmon@link108"
  # devilspie2: per-app window rules (spotify and slack without a title bar), started by external/devilspie2.sh
  link "$REPO/dotfiles/linux/devilspie2/spotify.lua" "$HOME/.config/devilspie2/spotify.lua"
  link "$REPO/dotfiles/linux/devilspie2/slack.lua" "$HOME/.config/devilspie2/slack.lua"
else
  link "$REPO/config/ghostty/config" "$HOME/.config/ghostty/config"
  # aerospace tiling (cortile is the linux counterpart); alt-* binds, caps is option via macos/keyboard.sh
  link "$REPO/config/aerospace/aerospace.toml" "$HOME/.config/aerospace/aerospace.toml"
  # neovim (lazy.nvim bootstraps itself on first start; lazy-lock.json updates land in the repo)
  link "$REPO/config/nvim" "$HOME/.config/nvim"
  # tmux: only the conf is linked so tpm and its plugins install into ~/.config/tmux/plugins, not the repo
  link "$REPO/config/tmux/tmux.conf" "$HOME/.config/tmux/tmux.conf"
fi

# mise global tools
link "$SHARED/mise.toml"           "$HOME/.config/mise/config.toml"
