.PHONY: help build build-all build-base build-node build-python build-example clean test lint security-scan push tag run-example stop-example logs-example monitoring-up monitoring-down monitoring-logs

# Variables
DOCKER_REGISTRY ?= docker.io
DOCKER_REPO ?= your-username
VERSION ?= 1.0.0
BUILD_DATE := $(shell date -u +'%Y-%m-%dT%H:%M:%SZ')
VCS_REF := $(shell git rev-parse --short HEAD 2>/dev/null || echo "dev")

# Colors for output
COLOR_RESET = \033[0m
COLOR_BOLD = \033[1m
COLOR_GREEN = \033[32m
COLOR_YELLOW = \033[33m
COLOR_BLUE = \033[34m

# Default target
.DEFAULT_GOAL := help

## help: Display this help message
help:
	@echo "$(COLOR_BOLD)Docker Base Images - Available Commands$(COLOR_RESET)"
	@echo ""
	@echo "$(COLOR_BLUE)Build Commands:$(COLOR_RESET)"
	@echo "  make build-all          - Build all base images"
	@echo "  make build-base         - Build Debian base image"
	@echo "  make build-node         - Build Node.js base image"
	@echo "  make build-python       - Build Python base image"
	@echo "  make build-example      - Build example Node.js app"
	@echo ""
	@echo "$(COLOR_BLUE)Run Commands:$(COLOR_RESET)"
	@echo "  make run-example        - Run the example Node.js application"
	@echo "  make stop-example       - Stop the example application"
	@echo "  make logs-example       - View logs from example app"
	@echo ""
	@echo "$(COLOR_BLUE)Testing & Quality:$(COLOR_RESET)"
	@echo "  make test               - Run tests"
	@echo "  make lint               - Lint Dockerfiles"
	@echo "  make security-scan      - Run security scans on images"
	@echo ""
	@echo "$(COLOR_BLUE)Monitoring:$(COLOR_RESET)"
	@echo "  make monitoring-up      - Start monitoring stack"
	@echo "  make monitoring-down    - Stop monitoring stack"
	@echo "  make monitoring-logs    - View monitoring logs"
	@echo ""
	@echo "$(COLOR_BLUE)Utility Commands:$(COLOR_RESET)"
	@echo "  make clean              - Remove all built images"
	@echo "  make tag                - Tag images for registry"
	@echo "  make push               - Push images to registry"
	@echo "  make version            - Show version information"
	@echo ""

## version: Display version information
version:
	@echo "Version: $(VERSION)"
	@echo "Build Date: $(BUILD_DATE)"
	@echo "VCS Ref: $(VCS_REF)"

## build-all: Build all base images
build-all: build-base build-node build-python
	@echo "$(COLOR_GREEN)✓ All base images built successfully$(COLOR_RESET)"

## build-base: Build Debian base image
build-base:
	@echo "$(COLOR_YELLOW)Building Debian base image...$(COLOR_RESET)"
	@docker build \
		--file docker/base/debian-base.Dockerfile \
		--tag debian-base:$(VERSION) \
		--tag debian-base:latest \
		--build-arg BUILD_DATE=$(BUILD_DATE) \
		--build-arg VERSION=$(VERSION) \
		--build-arg VCS_REF=$(VCS_REF) \
		docker/
	@echo "$(COLOR_GREEN)✓ Debian base image built$(COLOR_RESET)"

## build-node: Build Node.js base image
build-node:
	@echo "$(COLOR_YELLOW)Building Node.js base image...$(COLOR_RESET)"
	@docker build \
		--file docker/base/node-base.Dockerfile \
		--tag node-base:$(VERSION) \
		--tag node-base:latest \
		--build-arg BUILD_DATE=$(BUILD_DATE) \
		--build-arg VERSION=$(VERSION) \
		--build-arg VCS_REF=$(VCS_REF) \
		docker/base/
	@echo "$(COLOR_GREEN)✓ Node.js base image built$(COLOR_RESET)"

## build-python: Build Python base image
build-python:
	@echo "$(COLOR_YELLOW)Building Python base image...$(COLOR_RESET)"
	@docker build \
		--file docker/base/python-base.Dockerfile \
		--tag python-base:$(VERSION) \
		--tag python-base:latest \
		--build-arg BUILD_DATE=$(BUILD_DATE) \
		--build-arg VERSION=$(VERSION) \
		--build-arg VCS_REF=$(VCS_REF) \
		docker/base/
	@echo "$(COLOR_GREEN)✓ Python base image built$(COLOR_RESET)"

## build-example: Build example Node.js application
build-example:
	@echo "$(COLOR_YELLOW)Building example Node.js application...$(COLOR_RESET)"
	@docker build \
		--file examples/node-app/Dockerfile \
		--tag demo-node:$(VERSION) \
		--tag demo-node:latest \
		--build-arg BUILD_DATE=$(BUILD_DATE) \
		--build-arg VERSION=$(VERSION) \
		--build-arg VCS_REF=$(VCS_REF) \
		examples/node-app/
	@echo "$(COLOR_GREEN)✓ Example application built$(COLOR_RESET)"

## run-example: Run the example Node.js application
run-example: build-example
	@echo "$(COLOR_YELLOW)Starting example application...$(COLOR_RESET)"
	@docker run -d \
		--name demo-node \
		-p 8080:8080 \
		-e NODE_ENV=production \
		demo-node:latest
	@echo "$(COLOR_GREEN)✓ Example app running at http://localhost:8080$(COLOR_RESET)"
	@echo "  Health check: http://localhost:8080/health"
	@echo "  Metrics: http://localhost:8080/metrics"

## stop-example: Stop the example application
stop-example:
	@echo "$(COLOR_YELLOW)Stopping example application...$(COLOR_RESET)"
	@docker stop demo-node 2>/dev/null || true
	@docker rm demo-node 2>/dev/null || true
	@echo "$(COLOR_GREEN)✓ Example app stopped$(COLOR_RESET)"

## logs-example: View logs from example application
logs-example:
	@docker logs -f demo-node

## test: Run tests
test:
	@echo "$(COLOR_YELLOW)Running tests...$(COLOR_RESET)"
	@cd examples/node-app && npm test
	@echo "$(COLOR_GREEN)✓ Tests passed$(COLOR_RESET)"

## lint: Lint Dockerfiles using hadolint
lint:
	@echo "$(COLOR_YELLOW)Linting Dockerfiles...$(COLOR_RESET)"
	@if command -v hadolint >/dev/null 2>&1; then \
		hadolint docker/base/debian-base.Dockerfile || true; \
		hadolint docker/base/node-base.Dockerfile || true; \
		hadolint docker/base/python-base.Dockerfile || true; \
		hadolint examples/node-app/Dockerfile || true; \
		echo "$(COLOR_GREEN)✓ Linting complete$(COLOR_RESET)"; \
	else \
		echo "$(COLOR_YELLOW)⚠ hadolint not installed. Install with: brew install hadolint$(COLOR_RESET)"; \
	fi

## security-scan: Run security scans using trivy
security-scan: build-all build-example
	@echo "$(COLOR_YELLOW)Running security scans...$(COLOR_RESET)"
	@if command -v trivy >/dev/null 2>&1; then \
		trivy image --severity HIGH,CRITICAL debian-base:latest; \
		trivy image --severity HIGH,CRITICAL node-base:latest; \
		trivy image --severity HIGH,CRITICAL python-base:latest; \
		trivy image --severity HIGH,CRITICAL demo-node:latest; \
		echo "$(COLOR_GREEN)✓ Security scan complete$(COLOR_RESET)"; \
	else \
		echo "$(COLOR_YELLOW)⚠ trivy not installed. Install with: brew install trivy$(COLOR_RESET)"; \
	fi

## monitoring-up: Start monitoring stack
monitoring-up:
	@echo "$(COLOR_YELLOW)Starting monitoring stack...$(COLOR_RESET)"
	@cd monitoring && docker compose up -d
	@echo "$(COLOR_GREEN)✓ Monitoring stack started$(COLOR_RESET)"
	@echo "  Prometheus: http://localhost:9090"
	@echo "  Grafana: http://localhost:3000 (admin/admin)"
	@echo "  cAdvisor: http://localhost:8081"

## monitoring-down: Stop monitoring stack
monitoring-down:
	@echo "$(COLOR_YELLOW)Stopping monitoring stack...$(COLOR_RESET)"
	@cd monitoring && docker compose down
	@echo "$(COLOR_GREEN)✓ Monitoring stack stopped$(COLOR_RESET)"

## monitoring-logs: View monitoring logs
monitoring-logs:
	@cd monitoring && docker compose logs -f

## tag: Tag images for registry
tag: build-all
	@echo "$(COLOR_YELLOW)Tagging images for $(DOCKER_REGISTRY)/$(DOCKER_REPO)...$(COLOR_RESET)"
	@docker tag debian-base:$(VERSION) $(DOCKER_REGISTRY)/$(DOCKER_REPO)/debian-base:$(VERSION)
	@docker tag debian-base:latest $(DOCKER_REGISTRY)/$(DOCKER_REPO)/debian-base:latest
	@docker tag node-base:$(VERSION) $(DOCKER_REGISTRY)/$(DOCKER_REPO)/node-base:$(VERSION)
	@docker tag node-base:latest $(DOCKER_REGISTRY)/$(DOCKER_REPO)/node-base:latest
	@docker tag python-base:$(VERSION) $(DOCKER_REGISTRY)/$(DOCKER_REPO)/python-base:$(VERSION)
	@docker tag python-base:latest $(DOCKER_REGISTRY)/$(DOCKER_REPO)/python-base:latest
	@echo "$(COLOR_GREEN)✓ Images tagged$(COLOR_RESET)"

## push: Push images to registry
push: tag
	@echo "$(COLOR_YELLOW)Pushing images to registry...$(COLOR_RESET)"
	@docker push $(DOCKER_REGISTRY)/$(DOCKER_REPO)/debian-base:$(VERSION)
	@docker push $(DOCKER_REGISTRY)/$(DOCKER_REPO)/debian-base:latest
	@docker push $(DOCKER_REGISTRY)/$(DOCKER_REPO)/node-base:$(VERSION)
	@docker push $(DOCKER_REGISTRY)/$(DOCKER_REPO)/node-base:latest
	@docker push $(DOCKER_REGISTRY)/$(DOCKER_REPO)/python-base:$(VERSION)
	@docker push $(DOCKER_REGISTRY)/$(DOCKER_REPO)/python-base:latest
	@echo "$(COLOR_GREEN)✓ Images pushed to registry$(COLOR_RESET)"

## clean: Remove all built images and containers
clean: stop-example monitoring-down
	@echo "$(COLOR_YELLOW)Cleaning up Docker images...$(COLOR_RESET)"
	@docker rmi -f debian-base:latest debian-base:$(VERSION) 2>/dev/null || true
	@docker rmi -f node-base:latest node-base:$(VERSION) 2>/dev/null || true
	@docker rmi -f python-base:latest python-base:$(VERSION) 2>/dev/null || true
	@docker rmi -f demo-node:latest demo-node:$(VERSION) 2>/dev/null || true
	@docker system prune -f
	@echo "$(COLOR_GREEN)✓ Cleanup complete$(COLOR_RESET)"

