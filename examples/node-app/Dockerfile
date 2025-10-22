# syntax=docker/dockerfile:1

# Build stage
FROM node:20-bookworm-slim AS builder

WORKDIR /build

# Copy package files
COPY package*.json ./

# Install dependencies (including dev dependencies for build)
RUN npm ci --include=dev

# Copy application source
COPY . .

# Production stage
FROM node:20-bookworm-slim AS production

# Build arguments
ARG BUILD_DATE
ARG VERSION=1.0.0
ARG VCS_REF

# Labels
LABEL org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.title="Node.js Demo Application" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.revision="${VCS_REF}"

# Install security updates and tini
RUN apt-get update \
 && apt-get upgrade -y \
 && apt-get install -y --no-install-recommends tini \
 && rm -rf /var/lib/apt/lists/* \
 && apt-get clean

# Create non-root user
RUN groupadd -r -g 10001 appgroup \
 && useradd -r -u 10001 -g appgroup appuser \
 && mkdir -p /app \
 && chown -R appuser:appgroup /app

WORKDIR /app

# Copy package files and install production dependencies only
COPY --chown=appuser:appgroup package*.json ./
RUN if [ -f package-lock.json ]; then \
      npm ci --omit=dev --ignore-scripts; \
    else \
      npm install --omit=dev --ignore-scripts; \
    fi \
 && npm cache clean --force

# Copy application files
COPY --chown=appuser:appgroup server.js ./

# Switch to non-root user
USER appuser

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD node -e "require('http').get('http://localhost:8080/health', (r) => process.exit(r.statusCode === 200 ? 0 : 1))"

# Use tini for proper signal handling
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["node", "server.js"]
