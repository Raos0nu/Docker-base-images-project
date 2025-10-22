# syntax=docker/dockerfile:1
FROM node:20-bookworm-slim AS base

# Build arguments for versioning and metadata
ARG BUILD_DATE
ARG VERSION=1.0.0
ARG VCS_REF
ARG NODE_ENV=production

# Labels following OCI standards
LABEL org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.title="Node.js Base Image" \
      org.opencontainers.image.description="Hardened Node.js 20 base image with security best practices" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.revision="${VCS_REF}" \
      org.opencontainers.image.vendor="Your Organization" \
      org.opencontainers.image.licenses="MIT" \
      maintainer="your-email@example.com"

# Set environment variables
ENV NODE_ENV=${NODE_ENV} \
    NPM_CONFIG_LOGLEVEL=warn \
    NPM_CONFIG_UPDATE_NOTIFIER=false \
    NPM_CONFIG_FUND=false \
    NPM_CONFIG_AUDIT=false

# Install security updates and essential tools
RUN apt-get update \
 && apt-get upgrade -y \
 && apt-get install -y --no-install-recommends \
      tini=0.19.0-* \
      dumb-init=1.2.5-* \
 && rm -rf /var/lib/apt/lists/* \
 && apt-get clean

# Update npm to latest secure version
RUN npm install -g npm@latest \
 && npm cache clean --force

# Create non-root user with secure defaults
RUN groupadd -r -g 10001 appgroup \
 && useradd -r -u 10001 -g appgroup -s /sbin/nologin -c "Node Application User" appuser \
 && mkdir -p /app \
 && chown -R appuser:appgroup /app

WORKDIR /app

# Switch to non-root user
USER appuser

# Health check (can be overridden in application Dockerfile)
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD node -e "require('http').get('http://localhost:8080/health', (r) => process.exit(r.statusCode === 200 ? 0 : 1))"

# Use tini as init system
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["node"]
