# Set up the kas tooling for this project in the current shell.
# Usage:  source env.sh
#
# - syncs the Python environment from uv.lock (pinned kas version)
# - activates .venv, so kas and kas-container are on the PATH
# - selects the Debian 12 build container (validated for Yocto Scarthgap)

# Refuse to run as a script: activation only works when sourced
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    echo "Use: source ${0##*/}" >&2
    exit 1
fi

_proj_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! command -v uv > /dev/null 2>&1; then
    echo "uv not found. Install it with:" >&2
    echo "  curl -LsSf https://astral.sh/uv/install.sh | sh" >&2
    unset _proj_dir
    return 1
fi

if ! uv sync --frozen --project "$_proj_dir"; then
    echo "uv sync failed" >&2
    unset _proj_dir
    return 1
fi

# shellcheck disable=SC1091
source "$_proj_dir/.venv/bin/activate"
export KAS_CONTAINER_IMAGE_DISTRO=debian-bookworm

echo "kas environment ready: $(kas --version 2>&1 | head -n 1), container: $KAS_CONTAINER_IMAGE_DISTRO"
unset _proj_dir
