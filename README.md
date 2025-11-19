# 🐳 Production-Ready Docker Base Images

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Docker](https://img.shields.io/badge/Docker-20.10+-blue.svg)](https://www.docker.com/)
[![Security](https://img.shields.io/badge/Security-Hardened-green.svg)](#security-features)

A collection of **production-ready, security-hardened Docker base images** for modern application development. This project provides standardized, reusable base images following industry best practices for Node.js, Python, and Debian environments.

## 🎯 Features

- **🔒 Security First**: Non-root users, minimal attack surface, regular security updates
- **📦 Multi-Stage Builds**: Optimized image sizes with builder patterns
- **🏥 Health Checks**: Built-in health and readiness probes
- **📊 Observability**: Prometheus metrics and comprehensive logging
- **⚡ Performance**: Optimized layer caching and minimal dependencies
- **🔄 CI/CD Ready**: GitHub Actions pipeline with automated testing and security scanning
- **📚 Well Documented**: Comprehensive documentation and examples
- **🛠️ Developer Experience**: Makefile automation for common tasks

## 📋 Table of Contents

- [Quick Start](#quick-start)
- [Available Images](#available-images)
- [Usage Examples](#usage-examples)
- [Security Features](#security-features)
- [Monitoring](#monitoring)
- [Development](#development)
- [Contributing](#contributing)
- [License](#license)

## 🚀 Quick Start

### Prerequisites

- Docker 20.10 or higher
- Docker Compose 2.0 or higher (for monitoring stack)
- Make (optional, for automation)

### Build All Base Images

```bash
# Using Make (recommended)
make build-all

# Or manually
docker build -f docker/base/debian-base.Dockerfile -t debian-base:latest docker/
docker build -f docker/base/node-base.Dockerfile -t node-base:latest docker/base/
docker build -f docker/base/python-base.Dockerfile -t python-base:latest docker/base/
```

### Run Example Application

```bash
# Using Make
make run-example

# Or manually
cd examples/node-app
docker build -t demo-node:latest .
docker run -p 8080:8080 demo-node:latest
```

Visit http://localhost:8080 to see the running application.

Test the endpoints:
```bash
curl http://localhost:8080/          # Main endpoint
curl http://localhost:8080/health    # Health check
curl http://localhost:8080/ready     # Readiness check
curl http://localhost:8080/metrics   # Prometheus metrics
```

## 📦 Available Images

### Debian Base Image

Minimal Debian-based image with essential tooling.

**Features:**
- Based on `debian:bookworm-slim`
- Includes: ca-certificates, curl, tini
- Non-root user (UID 10001)
- Health check support

**Usage:**
```dockerfile
FROM debian-base:latest
COPY myapp /app/
CMD ["/app/myapp"]
```

### Node.js Base Image

Production-ready Node.js 20 environment.

**Features:**
- Based on `node:20-bookworm-slim`
- Latest npm and security updates
- Optimized environment variables
- Graceful shutdown support
- Built-in health checks

**Usage:**
```dockerfile
FROM node-base:latest
COPY package*.json ./
RUN npm ci --omit=dev
COPY . .
CMD ["node", "server.js"]
```

### Python Base Image

Secure Python 3.12 runtime environment.

**Features:**
- Based on `python:3.12-slim-bookworm`
- Updated pip, setuptools, wheel
- Optimized Python environment
- Non-root execution
- Health check ready

**Usage:**
```dockerfile
FROM python-base:latest
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
CMD ["python", "app.py"]
```

## 💡 Usage Examples

See the [examples](examples/) directory for complete working examples:

- **[Node.js Application](examples/node-app/)**: Production-ready HTTP server with health checks, metrics, and graceful shutdown

## 🔒 Security Features

This project implements multiple security best practices:

### Container Security
- ✅ **Non-root user execution** (UID 10001)
- ✅ **Minimal base images** (debian-slim variants)
- ✅ **No unnecessary packages**
- ✅ **Regular security updates**
- ✅ **Pinned package versions**
- ✅ **Read-only root filesystem compatible**

### Application Security
- ✅ **Security headers** (XSS protection, content sniffing prevention)
- ✅ **Graceful shutdown handling**
- ✅ **Error handling and logging**
- ✅ **Health and readiness probes**

### Build Security
- ✅ **Multi-stage builds** to minimize attack surface
- ✅ **Layer optimization** for better caching
- ✅ **No secrets in images**
- ✅ **OCI standard labels**

### Security Scanning

Run security scans on all images:

```bash
make security-scan
```

This uses [Trivy](https://github.com/aquasecurity/trivy) to scan for vulnerabilities.

## 📊 Monitoring

The project includes a complete monitoring stack with Prometheus, Grafana, and cAdvisor.

### Start Monitoring

```bash
make monitoring-up
```

### Access Monitoring Tools

- **Prometheus**: http://localhost:9090
- **Grafana**: http://localhost:3000 (admin/admin)
- **cAdvisor**: http://localhost:8081

### Stop Monitoring

```bash
make monitoring-down
```

### Available Metrics

All applications expose metrics at `/metrics`:
- Process uptime
- Memory usage (RSS, heap)
- Custom application metrics

## 🛠️ Development

### Project Structure

```
.
├── docker/
│   ├── base/
│   │   ├── debian-base.Dockerfile    # Debian base image
│   │   ├── node-base.Dockerfile      # Node.js base image
│   │   └── python-base.Dockerfile    # Python base image
│   └── entrypoint.sh                 # Generic entrypoint script
├── examples/
│   └── node-app/                     # Example Node.js application
│       ├── Dockerfile
│       ├── server.js
│       └── package.json
├── monitoring/
│   ├── docker-compose.yml            # Monitoring stack
│   └── prometheus.yml                # Prometheus configuration
├── .github/
│   └── workflows/                    # CI/CD pipelines
├── Makefile                          # Build automation
└── README.md
```

### Available Make Commands

```bash
make help              # Show all available commands
make build-all         # Build all base images
make build-example     # Build example application
make run-example       # Run example application
make test              # Run tests
make lint              # Lint Dockerfiles
make security-scan     # Security scanning
make clean             # Cleanup images and containers
```

### Building Images with Custom Tags

```bash
# Build with version tag
VERSION=2.0.0 make build-all

# Build and tag for registry
DOCKER_REGISTRY=ghcr.io DOCKER_REPO=myorg make tag

# Push to registry
DOCKER_REGISTRY=ghcr.io DOCKER_REPO=myorg make push
```

### Linting

Lint Dockerfiles using [hadolint](https://github.com/hadolint/hadolint):

```bash
make lint
```

### Testing

Run tests for example applications:

```bash
make test
```

## 🔧 Configuration

### Build Arguments

All images support the following build arguments:

| Argument | Description | Default |
|----------|-------------|---------|
| `BUILD_DATE` | Build timestamp | Current date/time |
| `VERSION` | Image version | `1.0.0` |
| `VCS_REF` | Git commit hash | Current commit |
| `NODE_ENV` | Node.js environment | `production` |
| `PYTHON_ENV` | Python environment | `production` |

### Environment Variables

#### Node.js Applications

| Variable | Default | Description |
|----------|---------|-------------|
| `PORT` | `8080` | Server port |
| `HOST` | `0.0.0.0` | Server host |
| `NODE_ENV` | `development` | Environment mode |
| `SHUTDOWN_TIMEOUT` | `10000` | Graceful shutdown timeout (ms) |

## 🤝 Contributing

Contributions are welcome! This project follows industry best practices for Docker containerization.

### Development Workflow

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes following the coding standards below
4. Test your changes (`make build-all && make test`)
5. Commit your changes with clear messages (`git commit -m 'feat: add new feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

### Coding Standards

**Dockerfile Best Practices:**
- Use specific base image tags (e.g., `debian:bookworm-slim`, not `debian:latest`)
- Minimize layers by combining RUN commands
- Order instructions for better caching (dependencies before code)
- Use `.dockerignore` to exclude unnecessary files
- Run as non-root user
- Include health checks

**Commit Message Format:**
- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation changes
- `style:` Formatting changes
- `refactor:` Code restructuring
- `test:` Adding tests
- `chore:` Maintenance tasks

### Security Guidelines

- Never commit secrets or sensitive information
- Keep dependencies updated
- Run security scans: `make security-scan`
- Follow least privilege principle (non-root users)
- Report security vulnerabilities privately (do not open public issues)

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Docker community for best practices
- Security hardening guidelines from CIS Docker Benchmark
- Container security insights from Snyk and Aqua Security

## 📚 Additional Resources

- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [Container Security Guide](https://cheatsheetseries.owasp.org/cheatsheets/Docker_Security_Cheat_Sheet.html)
- [Multi-Stage Builds](https://docs.docker.com/build/building/multi-stage/)
- [Health Checks](https://docs.docker.com/engine/reference/builder/#healthcheck)

## 📝 Project Overview

This project provides **production-ready, security-hardened Docker base images** optimized for modern application development. All images follow industry best practices including:

- ✅ Multi-stage builds for optimized image sizes
- ✅ Non-root user execution (UID 10001)
- ✅ Minimal base images (debian-slim variants)
- ✅ Health checks and readiness probes
- ✅ Prometheus metrics endpoints
- ✅ Graceful shutdown handling
- ✅ Security headers and best practices
- ✅ OCI standard labels
- ✅ Comprehensive monitoring support

### Available Base Images

1. **debian-base** - Minimal Debian-based image with essential tooling
2. **node-base** - Production-ready Node.js 20 environment
3. **python-base** - Secure Python 3.12 runtime environment

### Frontend Dashboard

The example Node.js application includes a beautiful web dashboard accessible at `http://localhost:8080` that displays:
- Real-time health status and uptime
- System metrics (memory usage, heap statistics)
- Project information and available base images
- API endpoint documentation
- Auto-refreshing data every 5 seconds

## 🚢 Deployment

### Docker

```bash
docker run -d \
  --name myapp \
  -p 8080:8080 \
  -e NODE_ENV=production \
  --memory="512m" \
  --cpus="1.0" \
  --restart unless-stopped \
  myapp:1.0.0
```

### Docker Compose

```yaml
version: '3.9'
services:
  app:
    build: .
    ports:
      - "8080:8080"
    environment:
      - NODE_ENV=production
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 30s
      timeout: 3s
      retries: 3
```

### Kubernetes

See the deployment examples in the repository for complete Kubernetes manifests with:
- Deployment configurations
- Service definitions
- Health and readiness probes
- Resource limits
- Security contexts

### Cloud Platforms

The images are compatible with:
- **AWS ECS/Fargate** - Use the provided task definitions
- **Google Cloud Run** - Deploy directly with gcloud
- **Azure Container Instances** - Use Azure Container Registry
- **Any Kubernetes cluster** - Use the provided manifests

## 💬 Support

For questions and support:
- Open an [issue](https://github.com/Raos0nu/Docker-base-images-project/issues)
- Check the [repository](https://github.com/Raos0nu/Docker-base-images-project) for examples

---

**Built with ❤️ for the Docker community**
