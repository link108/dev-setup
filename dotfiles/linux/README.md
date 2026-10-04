# Linux bootstrap

This is intentionally declarative and Brewfile-like.

## Files

- `apt.txt` — one APT package per line
- `flatpak.txt` — one Flathub app ID per line
- `external.txt` — vendor installers / .deb downloads
- `mise.toml` — language runtimes and CLI tool versions
- `bootstrap-linux.sh` — generic runner; it reads the files above

## external.txt format

```text
name|method|source
```

Supported methods:

- `script` -> `curl -fsSL URL | bash`
- `script-sh` -> `curl -fsSL URL | sh`
- `deb` -> download `.deb`, then install with APT

Example:

```text
codex|script-sh|https://chatgpt.com/codex/install.sh
claude|script-sh|https://claude.ai/install.sh
k3d|script|https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh
chrome|deb|https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
```

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
