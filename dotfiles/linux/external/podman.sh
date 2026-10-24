#!/usr/bin/env bash
set -euo pipefail

# Podman stands in for OrbStack/Docker Desktop (podman + podman-docker in apt.txt). Rootless and
# daemonless, so "on at startup" means two user units, started at login: podman.socket serves the
# Docker API for tools that want a socket (DOCKER_HOST is set in shared/zsh/.zshrc), and
# podman-restart brings back containers run with --restart=always.
systemctl --user enable --now podman.socket podman-restart.service
