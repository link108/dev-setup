#!/usr/bin/env bash
set -euo pipefail

if command -v codex >/dev/null 2>&1; then
  echo "Codex already installed"
  exit 0
fi

curl -fsSL https://chatgpt.com/codex/install.sh | sh
