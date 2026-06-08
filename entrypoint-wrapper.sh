#!/bin/bash
# Entrypoint wrapper for Kyber WISP/Pterodactyl egg
# WISP mounts server files at /home/container and runs as user 999:999.
# /root/.local and /mnt/battlefront are symlinked to /home/container at build time.

mkdir -p /home/container/.local/share/kyber/module
mkdir -p /home/container/.local/share/maxima/wine/prefix
mkdir -p /home/container/battlefront

# Copy module files into the game directory so Wine can find them
# as DLL dependencies when injecting Kyber.dll
mkdir -p /home/container/battlefront/
cp -n /home/container/.local/share/kyber/module/vivoxsdk.dll /home/container/battlefront/vivoxsdk.dll 2>/dev/null || true

# Force 64-bit Wine prefix
export WINEARCH=win64
export WINEPREFIX=/home/container/.local/share/maxima/wine/prefix

# Hand off to the original Kyber entrypoint
exec /opt/kyber/entrypoint.sh "$@"