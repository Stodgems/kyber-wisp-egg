#!/bin/bash
# Entrypoint wrapper for Kyber WISP/Pterodactyl egg
# Fully replaces the original entrypoint, skipping the vivoxsdk.dll cp
# which fails when module files haven't been downloaded yet.
# WISP mounts at /home/container, /root/.local and /mnt/battlefront are symlinked there.

set -uo pipefail

MODULE_DIR=/home/container/.local/share/kyber/module
WINEPREFIX=/home/container/.local/share/maxima/wine/prefix

# Create required directories
mkdir -p "${MODULE_DIR}"
mkdir -p "${WINEPREFIX}"
mkdir -p /home/container/battlefront

export WINEARCH=win64
export WINEPREFIX
export KYBER_BYPASS_DOCKER_I_REALLY_KNOW_WHAT_I_AM_DOING=1

# Initialise Wine prefix
WINEPREFIX="${WINEPREFIX}" /home/kyber/wine/bin/wine64 winecfg || true

echo "Starting KYBER Server named '${KYBER_SERVER_NAME:-unnamed}'"

args=(
  /opt/kyber/kyber_cli start_server
  --show-console
  --credentials="${MAXIMA_CREDENTIALS}"
  --token "${KYBER_TOKEN}"
  --game-path /home/container/battlefront/starwarsbattlefrontii.exe
  --module-path="${MODULE_DIR}"
  --verbose
)
args+=("$@")

exec "${args[@]}"