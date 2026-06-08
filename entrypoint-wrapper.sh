#!/bin/bash
# Entrypoint wrapper for Kyber WISP/Pterodactyl egg
# WISP mounts server files at /home/container and runs as user 999:999.
# We pre-create the .local structure there before Kyber's entrypoint runs.
# /root/.local and /mnt/battlefront are symlinked to /home/container at build time.

mkdir -p /home/container/.local/share/kyber/module
mkdir -p /home/container/.local/share/maxima
mkdir -p /home/container/battlefront

# Hand off to the original Kyber entrypoint
exec /opt/kyber/entrypoint.sh "$@"