#!/bin/bash
# Entrypoint wrapper for Kyber WISP/Pterodactyl egg
# Replaces the original entrypoint entirely to fix ordering issues.
# WISP mounts server files at /home/container and runs as user 999:999.
# /root/.local and /mnt/battlefront are symlinked to /home/container at build time.

set -euo pipefail

MODULE_DIR=/home/container/.local/share/kyber/module
WINE="/home/kyber/wine/bin/wine64"
WINEPREFIX=/home/container/.local/share/maxima/wine/prefix

# Create required directories
mkdir -p "${MODULE_DIR}"
mkdir -p "${WINEPREFIX}"
mkdir -p /home/container/battlefront

export WINEARCH=win64
export WINEPREFIX

# Step 1: Download Kyber module files via kyber_cli if not present
if [ ! -s "${MODULE_DIR}/Kyber.dll" ]; then
    echo "Downloading Kyber module files..."
    cd /home/kyber
    ./kyber_cli update_module --module-path="${MODULE_DIR}" || \
    ./kyber_cli download_module --module-path="${MODULE_DIR}" || \
    ./kyber_cli install --module-path="${MODULE_DIR}" || true
fi

# Step 2: Copy vivoxsdk.dll to game folder (as original entrypoint does)
if [ -f "${MODULE_DIR}/vivoxsdk.dll" ]; then
    cp "${MODULE_DIR}/vivoxsdk.dll" /home/container/battlefront/vivoxsdk.dll
else
    echo "WARNING: vivoxsdk.dll not found in module dir, continuing anyway..."
fi

# Step 3: Initialise Wine prefix
"${WINE}" winecfg || true

export KYBER_BYPASS_DOCKER_I_REALLY_KNOW_WHAT_I_AM_DOING=1
echo "Starting KYBER Server named '${KYBER_SERVER_NAME:-unnamed}'"

args=(
  /home/kyber/kyber_cli start_server
  --show-console
  --credentials="${MAXIMA_CREDENTIALS}"
  --token "${KYBER_TOKEN}"
  --game-path /home/container/battlefront/starwarsbattlefrontii.exe
  --module-path="${MODULE_DIR}"
  --verbose
)
args+=("$@")

exec "${args[@]}"