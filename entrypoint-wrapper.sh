#!/bin/bash
# Entrypoint wrapper for Kyber WISP/Pterodactyl egg
# Fully replaces the original entrypoint.
# WISP mounts at /home/container, /root/.local and /mnt/battlefront are symlinked there.

set -uo pipefail

MODULE_DIR=/home/container/.local/share/kyber/module
WINEPREFIX=/home/container/.local/share/maxima/wine/prefix
MODS_DIR=/home/container/mods

# Create required directories
mkdir -p "${MODULE_DIR}"
mkdir -p "${WINEPREFIX}"
mkdir -p /home/container/battlefront
mkdir -p "${MODS_DIR}"

# Restore all module files from copies saved at build time
for f in vivoxsdk.dll Kyber.dll ca_root.pem VanillaBundleAggregation.kb; do
    if [ ! -f "${MODULE_DIR}/${f}" ]; then
        cp "/opt/kyber/${f}" "${MODULE_DIR}/${f}"
    fi
done

# Copy vivoxsdk.dll to game folder as the original entrypoint does
cp "${MODULE_DIR}/vivoxsdk.dll" /home/container/battlefront/vivoxsdk.dll

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

# Add mod folder if KYBER_MOD_FOLDER is set
if [[ -n "${KYBER_MOD_FOLDER:-}" ]]; then
    args+=(--mod-folder="${KYBER_MOD_FOLDER}")
fi

args+=("$@")

exec "${args[@]}"