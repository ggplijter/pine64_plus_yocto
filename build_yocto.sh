#!/usr/bin/env bash
# Build or work with the Pine64+ Yocto image through kas-container.
#
# Usage:
#   ./build_yocto.sh                 build the image (default)
#   ./build_yocto.sh shell           open a bitbake shell in the container
#   ./build_yocto.sh lock            update the layer lock file
#   ./build_yocto.sh <cmd> [opts]    any kas-container command with options
#
# Works with or without "source env.sh": uv run uses the pinned kas version.
set -euo pipefail

cd "$(dirname "$(readlink -f "$0")")"

CONFIG=pine64-plus.yml
CMD=${1:-build}
shift || true

export KAS_CONTAINER_IMAGE_DISTRO="${KAS_CONTAINER_IMAGE_DISTRO:-debian-bookworm}"

# Catch YAML mistakes (indentation, tabs) before starting the container
uv run --frozen python -c 'import sys, yaml; yaml.safe_load(open(sys.argv[1]))' "$CONFIG"
echo "$CONFIG: valid YAML"

exec uv run --frozen kas-container "$CMD" "$@" "$CONFIG"
