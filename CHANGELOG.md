# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Comprehensive Makefile for build automation
- Security scanning with Trivy integration
- Linting with hadolint support
- Project configuration files (.gitignore, .dockerignore, .editorconfig)
- Comprehensive documentation (README, CONTRIBUTING, LICENSE)
- Graceful shutdown handling in Node.js example
- Health and readiness check endpoints
- Prometheus metrics endpoint
- Structured logging
- Security headers in applications
- Multi-stage Docker builds
- OCI standard labels
- GitHub Actions CI/CD pipeline

### Changed
- Enhanced all Dockerfiles with security best practices
- Improved Node.js example with production-ready features
- Updated monitoring stack configuration
- Non-root user execution with dedicated groups (appgroup)
- Pinned package versions for security

### Security
- Added non-root user execution (UID 10001)
- Implemented security headers (X-Frame-Options, X-Content-Type-Options, etc.)
- Pinned dependency versions
- Regular security updates in base images
- Minimal base images (debian-slim)

## [1.0.0] - 2025-01-01

### Added
- Debian base image (debian:bookworm-slim)
- Node.js base image (node:20-bookworm-slim)
- Python base image (python:3.12-slim-bookworm)
- Example Node.js application
- Monitoring stack with Prometheus, Grafana, and cAdvisor
- Basic CI pipeline for builds
- Entrypoint script for Debian base image
- Health checks for containers
- Basic documentation

### Security
- Non-root user execution
- Minimal dependencies
- Clean apt cache to reduce image size

[Unreleased]: https://github.com/yourusername/docker-base-images/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/yourusername/docker-base-images/releases/tag/v1.0.0
