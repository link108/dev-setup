#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
case "$(uname -s)" in
	Darwin)
		$ROOT/bootstrap-macos.sh
		;;
	Linux)
		$ROOT/linux/bootstrap-linux.sh
		;;
esac
