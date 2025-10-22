# syntax=docker/dockerfile:1

# Build stage
FROM python:3.12-slim-bookworm AS builder

WORKDIR /build

# Install build dependencies
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      gcc \
      python3-dev \
 && rm -rf /var/lib/apt/lists/*

# Copy requirements and install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir --user -r requirements.txt

# Production stage
FROM python:3.12-slim-bookworm AS production

# Build arguments
ARG BUILD_DATE
ARG VERSION=1.0.0
ARG VCS_REF

# Labels
LABEL org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.title="Python Demo Application" \
      org.opencontainers.image.description="Example Python Flask application" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.revision="${VCS_REF}"

# Set environment variables
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONFAULTHANDLER=1 \
    PYTHONHASHSEED=random \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    FLASK_ENV=production \
    PORT=8080

# Install runtime dependencies and tini
RUN apt-get update \
 && apt-get upgrade -y \
 && apt-get install -y --no-install-recommends \
      tini=0.19.0-* \
      curl=7.88.1-* \
 && rm -rf /var/lib/apt/lists/* \
 && apt-get clean

# Create non-root user
RUN groupadd -r -g 10001 appgroup \
 && useradd -r -u 10001 -g appgroup -s /sbin/nologin -c "Python Application User" appuser \
 && mkdir -p /app \
 && chown -R appuser:appgroup /app

WORKDIR /app

# Copy dependencies from builder
COPY --from=builder --chown=appuser:appgroup /root/.local /home/appuser/.local

# Copy application files
COPY --chown=appuser:appgroup app.py .

# Update PATH to include user-installed packages
ENV PATH=/home/appuser/.local/bin:$PATH

# Switch to non-root user
USER appuser

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8080/health').read()" || exit 1

# Use tini for proper signal handling
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["python", "app.py"]

