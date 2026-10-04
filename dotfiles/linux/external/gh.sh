#!/usr/bin/env bash
set -euo pipefail

if command -v gh >/dev/null 2>&1; then
  echo "gh already installed"
  exit 0
fi

# GitHub's own apt repo; Ubuntu's gh package lags far behind.
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
  | sudo tee /usr/share/keyrings/githubcli-archive-keyring.gpg >/dev/null
sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
  | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null

sudo apt update
sudo apt install -y gh
