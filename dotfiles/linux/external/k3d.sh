#!/usr/bin/env bash
set -euo pipefail

if command -v k3d >/dev/null 2>&1; then
  echo "k3d already installed"
  exit 0
fi

curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
