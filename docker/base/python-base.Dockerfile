# syntax=docker/dockerfile:1
FROM python:3.12-slim-bookworm AS base

# Build arguments for versioning and metadata
ARG BUILD_DATE
ARG VERSION=1.0.0
ARG VCS_REF
ARG PYTHON_ENV=production

# Labels following OCI standards
LABEL org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.title="Python Base Image" \
      org.opencontainers.image.description="Hardened Python 3.12 base image with security best practices" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.revision="${VCS_REF}" \
      org.opencontainers.image.vendor="Your Organization" \
      org.opencontainers.image.licenses="MIT" \
      maintainer="your-email@example.com"

# Set environment variables for Python
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONFAULTHANDLER=1 \
    PYTHONHASHSEED=random \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_DEFAULT_TIMEOUT=100

# Install security updates and essential tools
RUN apt-get update \
 && apt-get upgrade -y \
 && apt-get install -y --no-install-recommends \
      tini \
      curl \
 && rm -rf /var/lib/apt/lists/* \
 && apt-get clean

# Upgrade pip, setuptools, and wheel to latest secure versions
RUN pip install --no-cache-dir --upgrade \
      pip \
      setuptools \
      wheel

# Create non-root user with secure defaults
RUN groupadd -r -g 10001 appgroup \
 && useradd -r -u 10001 -g appgroup -s /sbin/nologin -c "Python Application User" appuser \
 && mkdir -p /app \
 && chown -R appuser:appgroup /app

WORKDIR /app

# Switch to non-root user
USER appuser

# Health check (can be overridden in application Dockerfile)
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8080/health').read()" || exit 1

# Use tini as init system
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["python"]
