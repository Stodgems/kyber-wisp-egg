FROM ghcr.io/armchairdevelopers/kyber-server:latest

USER root

# Pre-create the entire .local structure at build time with open permissions.
# WISP/Pterodactyl runs containers as a non-root user, so /root is not writable
# at runtime. Creating these directories here ensures they exist and are
# accessible regardless of which user the container runs as.
RUN mkdir -p /root/.local/share/kyber/module \
    && mkdir -p /root/.local/share/maxima \
    && touch /root/.local/share/kyber/module/vivoxsdk.dll \
    && chmod -R 777 /root \
    && chmod -R 777 /root/.local

# Copy wrapper entrypoint
COPY entrypoint-wrapper.sh /opt/kyber/entrypoint-wrapper.sh
RUN chmod +x /opt/kyber/entrypoint-wrapper.sh

ENTRYPOINT ["/opt/kyber/entrypoint-wrapper.sh"]