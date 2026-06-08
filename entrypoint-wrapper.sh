#!/bin/bash
# Entrypoint wrapper for Kyber WISP/Pterodactyl egg
# WISP mounts server files at /home/container and runs as user 999:999.
# /root/.local and /mnt/battlefront are symlinked to /home/container at build time.

# Create directories but do NOT create placeholder files.
# Kyber downloads the real module files (vivoxsdk.dll, Kyber.dll) on first run.
mkdir -p /home/container/.local/share/kyber/module
mkdir -p /home/container/.local/share/maxima/wine/prefix
mkdir -p /home/container/battlefront

# Force 64-bit Wine prefix
export WINEARCH=win64
export WINEPREFIX=/home/container/.local/share/maxima/wine/prefix

# Hand off to the original Kyber entrypoint
exec /opt/kyber/entrypoint.sh "$@"