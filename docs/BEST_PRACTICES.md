# Docker Base Images - Best Practices

This document outlines the best practices implemented in this project and recommendations for using Docker in production.

## Table of Contents

1. [Dockerfile Best Practices](#dockerfile-best-practices)
2. [Security Best Practices](#security-best-practices)
3. [Build Optimization](#build-optimization)
4. [Runtime Best Practices](#runtime-best-practices)
5. [Monitoring and Observability](#monitoring-and-observability)
6. [CI/CD Integration](#cicd-integration)

## Dockerfile Best Practices

### 1. Use Specific Base Image Tags

❌ **Bad:**
```dockerfile
FROM debian:latest
FROM node:latest
```

✅ **Good:**
```dockerfile
FROM debian:bookworm-slim
FROM node:20-bookworm-slim
```

**Why:** Using specific tags ensures reproducible builds and prevents unexpected breaking changes.

### 2. Use Multi-Stage Builds

✅ **Good:**
```dockerfile
# Build stage
FROM node:20-bookworm-slim AS builder
WORKDIR /build
COPY package*.json ./
RUN npm ci --include=dev
COPY . .

# Production stage
FROM node:20-bookworm-slim AS production
WORKDIR /app
COPY --from=builder /build/package*.json ./
RUN npm ci --omit=dev
COPY --from=builder /build/dist ./dist
```

**Why:** Reduces final image size by excluding build dependencies and intermediate files.

### 3. Minimize Layer Count

❌ **Bad:**
```dockerfile
RUN apt-get update
RUN apt-get install -y package1
RUN apt-get install -y package2
RUN rm -rf /var/lib/apt/lists/*
```

✅ **Good:**
```dockerfile
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      package1 \
      package2 \
 && rm -rf /var/lib/apt/lists/*
```

**Why:** Fewer layers mean smaller images and faster builds.

### 4. Order Instructions for Better Caching

✅ **Good:**
```dockerfile
# Copy dependency files first (changes less frequently)
COPY package.json package-lock.json ./
RUN npm ci

# Copy source code last (changes more frequently)
COPY . .
```

**Why:** Docker layer caching speeds up rebuilds when only code changes.

### 5. Use .dockerignore

✅ **Always create .dockerignore:**
```
node_modules/
.git/
.env
*.log
test/
*.md
```

**Why:** Reduces build context size and prevents sensitive files from being copied.

### 6. Add Health Checks

✅ **Good:**
```dockerfile
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD curl -f http://localhost:8080/health || exit 1
```

**Why:** Enables Docker and orchestrators to monitor container health.

## Security Best Practices

### 1. Run as Non-Root User

❌ **Bad:**
```dockerfile
FROM debian:bookworm-slim
# Running as root (default)
```

✅ **Good:**
```dockerfile
FROM debian:bookworm-slim
RUN groupadd -r -g 10001 appgroup \
 && useradd -r -u 10001 -g appgroup appuser
USER appuser
```

**Why:** Limits potential damage from container breakouts and vulnerabilities.

### 2. Use Minimal Base Images

✅ **Prefer slim variants:**
- `debian:bookworm-slim` over `debian:bookworm`
- `node:20-bookworm-slim` over `node:20`
- `python:3.12-slim-bookworm` over `python:3.12`

**Why:** Smaller attack surface, fewer vulnerabilities, smaller image size.

### 3. Pin Package Versions

✅ **Good:**
```dockerfile
RUN apt-get install -y \
      ca-certificates=20230311 \
      curl=7.88.1-*
```

**Why:** Ensures reproducible builds and prevents unexpected updates.

### 4. Scan for Vulnerabilities

```bash
# Using Trivy
trivy image myimage:latest

# Using Snyk
snyk container test myimage:latest
```

**Why:** Identifies known vulnerabilities before deployment.

### 5. Don't Store Secrets in Images

❌ **Bad:**
```dockerfile
ENV API_KEY=abc123
COPY .env .
```

✅ **Good:**
```bash
# Use runtime environment variables
docker run -e API_KEY=$API_KEY myimage

# Use Docker secrets (Swarm)
docker service create --secret my-secret myimage

# Use Kubernetes secrets
kubectl create secret generic my-secret --from-literal=key=value
```

### 6. Add Security Labels

✅ **Good:**
```dockerfile
LABEL org.opencontainers.image.vendor="Your Organization" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.version="${VERSION}"
```

## Build Optimization

### 1. Optimize Layer Caching

✅ **Order matters:**
```dockerfile
# 1. Base image (rarely changes)
FROM node:20-bookworm-slim

# 2. System dependencies (rarely changes)
RUN apt-get update && apt-get install -y curl

# 3. Application dependencies (changes occasionally)
COPY package*.json ./
RUN npm ci

# 4. Application code (changes frequently)
COPY . .
```

### 2. Use BuildKit

```bash
# Enable BuildKit
export DOCKER_BUILDKIT=1

# Or in docker-compose
export COMPOSE_DOCKER_CLI_BUILD=1
export DOCKER_BUILDKIT=1
```

**Benefits:**
- Parallel build stages
- Better caching
- Secrets mounting
- SSH agent forwarding

### 3. Leverage Build Arguments

```dockerfile
ARG NODE_ENV=production
ENV NODE_ENV=${NODE_ENV}
```

```bash
docker build --build-arg NODE_ENV=development .
```

### 4. Clean Up in Same Layer

✅ **Good:**
```dockerfile
RUN apt-get update \
 && apt-get install -y package \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*
```

**Why:** Removes temporary files in the same layer, reducing image size.

## Runtime Best Practices

### 1. Use Init System (Tini)

✅ **Good:**
```dockerfile
RUN apt-get install -y tini
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["node", "server.js"]
```

**Why:** Properly handles signals and prevents zombie processes.

### 2. Implement Graceful Shutdown

```javascript
// Node.js example
process.on('SIGTERM', async () => {
  console.log('SIGTERM received, shutting down gracefully');
  server.close(() => {
    process.exit(0);
  });
});
```

```python
# Python example
import signal
import sys

def graceful_shutdown(signum, frame):
    logger.info('Shutting down gracefully')
    sys.exit(0)

signal.signal(signal.SIGTERM, graceful_shutdown)
```

### 3. Set Resource Limits

```bash
docker run \
  --memory="512m" \
  --cpus="1.0" \
  myimage
```

```yaml
# Kubernetes
resources:
  requests:
    memory: "256Mi"
    cpu: "250m"
  limits:
    memory: "512Mi"
    cpu: "500m"
```

### 4. Use Read-Only Root Filesystem

```bash
docker run --read-only --tmpfs /tmp myimage
```

```yaml
# Kubernetes
securityContext:
  readOnlyRootFilesystem: true
```

## Monitoring and Observability

### 1. Expose Health Endpoints

```javascript
// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'healthy' });
});

// Readiness check
app.get('/ready', (req, res) => {
  const ready = !isShuttingDown;
  res.status(ready ? 200 : 503).json({ ready });
});
```

### 2. Expose Metrics

```javascript
// Prometheus metrics
app.get('/metrics', (req, res) => {
  res.set('Content-Type', 'text/plain');
  res.send(`
# HELP process_uptime_seconds Process uptime
# TYPE process_uptime_seconds gauge
process_uptime_seconds ${process.uptime()}
  `);
});
```

### 3. Use Structured Logging

```javascript
const logger = {
  info: (msg, meta = {}) => {
    console.log(JSON.stringify({
      level: 'info',
      msg,
      ...meta,
      timestamp: new Date().toISOString()
    }));
  }
};
```

### 4. Log to STDOUT/STDERR

✅ **Good:**
```javascript
console.log('Info message');
console.error('Error message');
```

❌ **Bad:**
```javascript
fs.appendFileSync('/var/log/app.log', 'message');
```

**Why:** Docker captures STDOUT/STDERR, enabling centralized logging.

## CI/CD Integration

### 1. Automated Testing

```yaml
# GitHub Actions example
- name: Build and test
  run: |
    docker build -t myimage:test .
    docker run myimage:test npm test
```

### 2. Security Scanning

```yaml
- name: Run Trivy scanner
  uses: aquasecurity/trivy-action@master
  with:
    image-ref: myimage:latest
    severity: 'CRITICAL,HIGH'
```

### 3. Automated Builds

```yaml
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
```

### 4. Image Tagging Strategy

```bash
# Semantic versioning
myimage:1.0.0
myimage:1.0
myimage:1
myimage:latest

# Git commit SHA
myimage:abc123f

# Branch name
myimage:main
myimage:develop
```

## Performance Best Practices

### 1. Use Alpine for Smaller Images (when appropriate)

```dockerfile
FROM node:20-alpine
FROM python:3.12-alpine
```

**Note:** Alpine uses musl libc instead of glibc, which can cause compatibility issues.

### 2. Minimize Installed Packages

```dockerfile
RUN apt-get install -y --no-install-recommends package
```

### 3. Use .dockerignore Aggressively

Include only necessary files in the build context.

### 4. Optimize Dependency Installation

```dockerfile
# Node.js: Use npm ci instead of npm install
RUN npm ci --omit=dev

# Python: Use --no-cache-dir
RUN pip install --no-cache-dir -r requirements.txt
```

## Additional Resources

- [Official Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [CIS Docker Benchmark](https://www.cisecurity.org/benchmark/docker)
- [OWASP Docker Security](https://cheatsheetseries.owasp.org/cheatsheets/Docker_Security_Cheat_Sheet.html)
- [Dockerfile Best Practices](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)
- [Snyk Docker Security](https://snyk.io/learn/docker-security/)

