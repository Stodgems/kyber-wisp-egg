FROM ghcr.io/armchairdevelopers/kyber-server:latest

USER root

# Preserve both module files before replacing /root/.local with a symlink
RUN cp /root/.local/share/kyber/module/vivoxsdk.dll /opt/kyber/vivoxsdk.dll \
    && cp /root/.local/share/kyber/module/Kyber.dll /opt/kyber/Kyber.dll

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