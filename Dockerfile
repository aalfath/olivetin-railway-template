# OliveTin for Railway: the official image, pinned by version and digest.
# Upstream: https://github.com/OliveTin/OliveTin  Docs: https://docs.olivetin.app
FROM ghcr.io/olivetin/olivetin:3000.22.0@sha256:e8441343ab8e3d13daa83f4cb2a00d9fa3510953a6040a556a805918f5636264

# The start script runs as root only to fix ownership of the Railway volume at
# /config, hashes the admin password, then drops to the image's `olivetin` user.
USER root
# Drop upstream's demo config (it lets guests run commands). The start script
# writes a login-required starter config to the volume on the first boot.
RUN rm -r /config/config.yaml /config/entities
COPY --chmod=0755 railway-start.sh /usr/local/bin/railway-start.sh
COPY --chmod=0644 config.default.yaml /opt/railway/config.default.yaml
COPY --chmod=0755 replace-config.sh /usr/local/bin/olivetin-replace-config

ENTRYPOINT ["/usr/local/bin/railway-start.sh"]
