FROM ghcr.io/armchairdevelopers/kyber-server:latest

USER root

# WISP mounts server files at /home/container and runs as user 999:999.
# The Kyber entrypoint expects /root/.local and /mnt/battlefront.
# We symlink both to /home/container so WISP's volume mount is used.

# Create the container user
RUN groupadd -g 999 container || true \
    && useradd -u 999 -g 999 -d /home/container -s /bin/bash container || true \
    && mkdir -p /home/container

# Remove existing /root/.local if present and replace with symlink
RUN rm -rf /root/.local \
    && ln -s /home/container/.local /root/.local

# Remove existing /mnt/battlefront and replace with symlink  
RUN mkdir -p /mnt \
    && rm -rf /mnt/battlefront \
    && ln -s /home/container/battlefront /mnt/battlefront

# Make /root accessible to user 999
RUN chmod 755 /root

# Copy wrapper entrypoint
COPY entrypoint-wrapper.sh /opt/kyber/entrypoint-wrapper.sh
RUN chmod +x /opt/kyber/entrypoint-wrapper.sh

ENTRYPOINT ["/opt/kyber/entrypoint-wrapper.sh"]