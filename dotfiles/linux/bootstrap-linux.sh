#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

trim() {
  local s="$1"
  s="${s#"${s%%[![:space:]]*}"}"
  s="${s%"${s##*[![:space:]]}"}"
  printf '%s' "$s"
}

install_apt_file() {
  local file="$1"


  if ! dpkg --print-foreign-architectures | grep -qx i386; then
	  sudo dpkg --add-architecture i386
  fi


  echo "==> apt update"
  sudo apt update

  while IFS= read -r package || [[ -n "$package" ]]; do
    package="$(trim "$package")"
    [[ -z "$package" ]] && continue
    [[ "$package" == \#* ]] && continue

    echo "==> apt install: $package"
    sudo apt install -y "$package"
  done < "$file"
}

install_flatpak_file() {
  local file="$1"

  if ! command -v flatpak >/dev/null 2>&1; then
    echo "==> installing flatpak"
    sudo apt install -y flatpak
  fi

  echo "==> ensuring Flathub"
  flatpak remote-add --if-not-exists \
    flathub \
    https://flathub.org/repo/flathub.flatpakrepo

  while IFS= read -r app || [[ -n "$app" ]]; do
    app="$(trim "$app")"
    [[ -z "$app" ]] && continue
    [[ "$app" == \#* ]] && continue

    echo "==> flatpak install: $app"
    flatpak install -y --noninteractive flathub "$app"
  done < "$file"
}

install_external_scripts() {
  local external_dir="$ROOT/external"

  if [[ ! -d "$external_dir" ]]; then
    echo "==> no external scripts directory found: $external_dir"
    return
  fi

  echo "==> running external installers"

  while IFS= read -r -d '' script; do
    echo "==> running: ${script#$ROOT/}"
    bash "$script"
  done < <(
    find "$external_dir" \
      -maxdepth 1 \
      -type f \
      -name '*.sh' \
      -print0 \
      | sort -z
  )
}

install_mise() {
  if ! command -v mise >/dev/null 2>&1; then
    echo "==> installing mise"
    curl https://mise.run | sh
  fi

  # shared/mise.toml is linked to ~/.config/mise/config.toml by link-dotfiles.sh
  echo "==> installing mise tools"
  "$HOME/.local/bin/mise" install
}

link_dotfiles() {
  echo "==> linking dotfiles"
  bash "$ROOT/../shared/link-dotfiles.sh"
}

configure_desktop() {
  bash "$ROOT/cinnamon.sh"
}

set_default_shell() {
  local zsh_path
  zsh_path="$(command -v zsh)"

  if [[ "$(getent passwd "$USER" | cut -d: -f7)" != "$zsh_path" ]]; then
    echo "==> setting default shell to $zsh_path (takes effect on next login)"
    sudo chsh -s "$zsh_path" "$USER"
  fi
}

main() {
  echo $ROOT
  install_apt_file "$ROOT/apt.txt"
  install_flatpak_file "$ROOT/flatpak.txt"
  install_external_scripts
  link_dotfiles
  install_mise
  set_default_shell
  configure_desktop

  echo
  echo "==> bootstrap complete"
}

main "$@"
