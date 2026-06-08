#!/bin/bash
# Entrypoint wrapper for Kyber WISP/Pterodactyl egg
# Ensures /root/.local is writable before the original entrypoint runs,
# fixing the vivoxsdk.dll permission error when running as non-root.

# Fix permissions on .local at runtime
mkdir -p /root/.local/share/kyber/module
mkdir -p /root/.local/share/maxima
chmod -R 777 /root/.local

# Hand off to the original Kyber entrypoint
exec /opt/kyber/entrypoint.sh "$@"
