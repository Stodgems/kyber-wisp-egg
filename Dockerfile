FROM ghcr.io/armchairdevelopers/kyber-server:latest

USER root

# WISP mounts server files at /home/container and runs as user 999:999.
# Symlink /root/.local and /mnt/battlefront to /home/container so WISP's
# volume mount is used for all runtime data.

# Create the container user
RUN groupadd -g 999 container || true \
    && useradd -u 999 -g 999 -d /home/container -s /bin/bash container || true \
    && mkdir -p /home/container

# Replace /root/.local with a symlink to /home/container/.local
RUN rm -rf /root/.local \
    && ln -s /home/container/.local /root/.local

# Replace /mnt/battlefront with a symlink to /home/container/battlefront
RUN mkdir -p /mnt \
    && rm -rf /mnt/battlefront \
    && ln -s /home/container/battlefront /mnt/battlefront

# Make /root accessible to user 999
RUN chmod 755 /root

# Copy wrapper entrypoint
COPY entrypoint-wrapper.sh /opt/kyber/entrypoint-wrapper.sh
RUN chmod +x /opt/kyber/entrypoint-wrapper.sh

ENTRYPOINT ["/opt/kyber/entrypoint-wrapper.sh"]