#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$ROOT/.." && pwd)"

install_brew() {
  if [[ ! -x /opt/homebrew/bin/brew ]]; then
    echo "==> installing homebrew"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
  eval "$(/opt/homebrew/bin/brew shellenv)"

  # homebrew ignores third-party taps until they're trusted (stored in ~/.homebrew/trust.json, not the repo)
  local tap
  for tap in $(sed -nE 's/^tap "([^"]+)".*/\1/p' "$REPO/brewfile"); do
    brew tap "$tap"
    brew trust --tap "$tap" >/dev/null
  done

  # a cask that fails (renamed, needs a password) shouldn't stop the rest of the bootstrap
  echo "==> brew bundle"
  brew bundle --file "$REPO/brewfile" || echo "==> brew bundle had failures, see above (brew bundle check --verbose)"

  # compinit refuses group-writable completion dirs ("insecure directories"), and installs can leave share g+w
  chmod go-w "$HOMEBREW_PREFIX/share" "$HOMEBREW_PREFIX/share/zsh" "$HOMEBREW_PREFIX/share/zsh/site-functions" "$HOMEBREW_PREFIX/share/zsh-completions"
}

link_dotfiles() {
  echo "==> linking dotfiles"
  bash "$ROOT/shared/link-dotfiles.sh"
}

install_tpm() {
  local tpm="$HOME/.config/tmux/plugins/tpm"
  if [[ ! -d "$tpm" ]]; then
    echo "==> cloning tpm -> $tpm"
    git clone https://github.com/tmux-plugins/tpm "$tpm"
  fi
  echo "==> installing tmux plugins"
  "$tpm/bin/install_plugins"
}

install_mise() {
  # shared/mise.toml is linked to ~/.config/mise/config.toml by link-dotfiles.sh
  echo "==> installing mise tools"
  mise install
}

start_aerospace() {
  # first launch asks for Accessibility permission; start-at-login in the config handles later logins
  if ! pgrep -xq AeroSpace; then
    echo "==> starting aerospace (grant it Accessibility in System Settings > Privacy & Security)"
    open -a AeroSpace
  fi
}

main() {
  install_brew
  link_dotfiles
  bash "$ROOT/shared/agent-skills.sh"
  install_mise
  install_tpm
  bash "$ROOT/macos/keyboard.sh"
  start_aerospace

  echo
  echo "==> bootstrap complete"
}

main "$@"
