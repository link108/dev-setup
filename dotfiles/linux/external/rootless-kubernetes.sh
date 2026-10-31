#!/usr/bin/env bash
set -euo pipefail

# Disposable Kubernetes clusters (kind from shared/mise.toml, k3d from external/k3d.sh) on rootless
# podman (external/podman.sh). Each node is a container running systemd and kubelet, which need
# to manage cgroups and iptables from inside it. Takes effect after logging out (or a reboot).
# Check: cat /sys/fs/cgroup/user.slice/user-$(id -u).slice/user@$(id -u).service/cgroup.controllers
# should list cpuset and io.

# Ubuntu's user@.service delegates only "pids memory cpu"; kubelet also needs cpuset and io.
# Delegate= lists in drop-ins are merged with the unit's. Undo: sudo rm the file.
delegate=/etc/systemd/system/user@.service.d/delegate.conf
if [[ ! -f "$delegate" ]]; then
  echo "==> rootless kubernetes: delegate cgroup controllers to user sessions (sudo)"
  sudo mkdir -p "$(dirname "$delegate")"
  sudo tee "$delegate" >/dev/null <<'CONF'
[Service]
Delegate=cpu cpuset io memory pids
CONF
  sudo systemctl daemon-reload
fi

# Rootless containers cannot load kernel modules, so the iptables ones kube-proxy and the CNI use
# are loaded at boot (kind's rootless guide lists these).
modules=/etc/modules-load.d/rootless-kubernetes.conf
if [[ ! -f "$modules" ]]; then
  echo "==> rootless kubernetes: load iptables modules at boot (sudo)"
  printf '%s\n' ip_tables iptable_nat ip6_tables ip6table_nat | sudo tee "$modules" >/dev/null
  sudo systemctl restart systemd-modules-load.service
fi

# Podman before 5.8 copies tar archives into containers (podman cp, the Docker archive API) in a
# way that breaks with "write |1: broken pipe" on small pipes (containers/buildah#6573). Pipes
# shrink to 8 KiB once a user is over fs.pipe-user-pages-soft (16384 pages), which Wine and
# browsers can push a desktop session past. 65536 pages is about 4000 full-size pipes.
pipes=/etc/sysctl.d/60-pipe-user-pages.conf
if [[ ! -f "$pipes" ]]; then
  echo "==> rootless kubernetes: raise the per-user pipe budget (sudo)"
  echo 'fs.pipe-user-pages-soft = 65536' | sudo tee "$pipes" >/dev/null
  sudo sysctl --quiet --load "$pipes"
fi
