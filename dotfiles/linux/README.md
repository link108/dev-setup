# Linux bootstrap

This is intentionally declarative and Brewfile-like.

## Files

- `apt.txt` — one APT package per line
- `flatpak.txt` — one Flathub app ID per line
- `external/*.sh` — vendor installers, each one idempotent
- `../shared/mise.toml` — language runtimes and CLI tool versions (linked to `~/.config/mise/config.toml`)
- `../shared/link-dotfiles.sh` — symlinks zshrc, vimrc, git aliases, ghostty config (`ghostty/config` on linux), cortile config
- `cortile/config.toml` — auto-tiling on top of Cinnamon (`external/cortile.sh` installs it), super keybinds modelled on `config/aerospace`
- `cinnamon.sh` — desktop prefs: wallpaper slideshow (`~/Documents/desktop-backgrounds`), top panel + Plank dock at bottom (macOS-ish), panel icon size, 6 workspaces on super+N / super+shift+N, no window-list badges
- `bootstrap-linux.sh` — generic runner; it reads the files above

## Run

```bash
chmod +x bootstrap-linux.sh
./bootstrap-linux.sh
```

## Notes

This keeps package intent in declarative files rather than hardcoding each app into the shell script.

Battle.net is still handled via Lutris.
Jagex is handled via Bolt.
CadQuery is best kept project-local/devcontainer-based rather than globally installed.
