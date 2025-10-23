# syntax=docker/dockerfile:1
FROM debian:bookworm-slim

# Build arguments for versioning and metadata
ARG BUILD_DATE
ARG VERSION=1.0.0
ARG VCS_REF

# Labels following OCI standards
LABEL org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.title="Debian Base Image" \
      org.opencontainers.image.description="Hardened Debian base image with security best practices" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.revision="${VCS_REF}" \
      org.opencontainers.image.vendor="Your Organization" \
      org.opencontainers.image.licenses="MIT" \
      maintainer="your-email@example.com"

# Install essential packages with security updates
RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
      tini \
 && apt-get upgrade -y \
 && rm -rf /var/lib/apt/lists/* \
 && apt-get clean

# Create non-root user with secure defaults
# Using high UID for better security in containerized environments
RUN groupadd -r -g 10001 appgroup \
 && useradd -r -u 10001 -g appgroup -s /sbin/nologin -c "Application User" appuser \
 && mkdir -p /app \
 && chown -R appuser:appgroup /app

WORKDIR /app

# Copy entrypoint script
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh \
 && chown appuser:appgroup /usr/local/bin/entrypoint.sh

# Switch to non-root user
USER appuser

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8080/health || exit 1

# Use tini as init system to handle signals properly
ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/entrypoint.sh"]
CMD []
