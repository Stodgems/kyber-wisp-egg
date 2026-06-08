FROM ghcr.io/armchairdevelopers/kyber-server:latest

USER root

# Pre-create the .local directory structure with open permissions
# so WISP/Pterodactyl containers running as non-root can write to it.
# This fixes the "cp: cannot stat '/root/.local/share/kyber/module/vivoxsdk.dll': Permission denied" error.
RUN mkdir -p /root/.local/share/kyber/module \
    && mkdir -p /root/.local/share/maxima \
    && touch /root/.local/share/kyber/module/vivoxsdk.dll \
    && chmod -R 777 /root/.local

# Wrap the original entrypoint so we can fix permissions at runtime too,
# in case the container user differs from root.
COPY entrypoint-wrapper.sh /opt/kyber/entrypoint-wrapper.sh
RUN chmod +x /opt/kyber/entrypoint-wrapper.sh

ENTRYPOINT ["/opt/kyber/entrypoint-wrapper.sh"]
