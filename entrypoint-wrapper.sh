#!/bin/bash
# Entrypoint wrapper for Kyber WISP/Pterodactyl egg
# WISP mounts server files at /home/container and runs as user 999:999.
# /root/.local and /mnt/battlefront are symlinked to /home/container at build time.

mkdir -p /home/container/.local/share/kyber/module
mkdir -p /home/container/.local/share/maxima/wine/prefix
mkdir -p /home/container/battlefront

# Hand off to the original Kyber entrypoint
exec /opt/kyber/entrypoint.sh "$@"