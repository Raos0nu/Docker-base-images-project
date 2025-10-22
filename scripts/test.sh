#!/usr/bin/env bash
#
# Test script for Docker base images
#

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Helper functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

test_passed() {
    ((TESTS_PASSED++))
    ((TESTS_RUN++))
    echo -e "${GREEN}✓${NC} $1"
}

test_failed() {
    ((TESTS_FAILED++))
    ((TESTS_RUN++))
    echo -e "${RED}✗${NC} $1"
}

# Test Docker installation
test_docker_installed() {
    log_info "Testing Docker installation..."
    if command -v docker &> /dev/null; then
        test_passed "Docker is installed"
        docker --version
    else
        test_failed "Docker is not installed"
        return 1
    fi
}

# Test image build
test_image_build() {
    local image=$1
    local dockerfile=$2
    local context=$3
    
    log_info "Building $image..."
    if docker build -f "$dockerfile" -t "$image:test" "$context" &> /dev/null; then
        test_passed "$image builds successfully"
    else
        test_failed "$image failed to build"
        return 1
    fi
}

# Test image size
test_image_size() {
    local image=$1
    local max_size_mb=$2
    
    local size_bytes=$(docker inspect "$image:test" --format='{{.Size}}')
    local size_mb=$((size_bytes / 1024 / 1024))
    
    if [ "$size_mb" -le "$max_size_mb" ]; then
        test_passed "$image size is $size_mb MB (limit: $max_size_mb MB)"
    else
        test_failed "$image size is $size_mb MB (exceeds limit: $max_size_mb MB)"
    fi
}

# Test container starts
test_container_start() {
    local image=$1
    local container_name=$2
    
    log_info "Starting container from $image..."
    if docker run -d --name "$container_name" "$image:test" &> /dev/null; then
        test_passed "Container $container_name started"
        sleep 2
    else
        test_failed "Container $container_name failed to start"
        return 1
    fi
}

# Test health check
test_health_check() {
    local url=$1
    local expected_status=$2
    
    log_info "Testing health check at $url..."
    local status=$(curl -s -o /dev/null -w "%{http_code}" "$url" || echo "000")
    
    if [ "$status" = "$expected_status" ]; then
        test_passed "Health check returned $status"
    else
        test_failed "Health check returned $status (expected $expected_status)"
    fi
}

# Test non-root user
test_nonroot_user() {
    local container=$1
    
    log_info "Testing non-root user in $container..."
    local user=$(docker exec "$container" whoami 2>/dev/null || echo "failed")
    
    if [ "$user" != "root" ]; then
        test_passed "Container runs as non-root user ($user)"
    else
        test_failed "Container runs as root user"
    fi
}

# Cleanup containers
cleanup() {
    log_info "Cleaning up test containers..."
    docker stop test-debian test-node test-python demo-node-test 2>/dev/null || true
    docker rm test-debian test-node test-python demo-node-test 2>/dev/null || true
    log_info "Cleanup complete"
}

# Main test execution
main() {
    echo "========================================="
    echo "Docker Base Images - Test Suite"
    echo "========================================="
    echo ""
    
    # Setup trap for cleanup
    trap cleanup EXIT
    
    # Test Docker installation
    test_docker_installed || exit 1
    echo ""
    
    # Test Debian base image
    log_info "Testing Debian Base Image"
    echo "========================================="
    test_image_build "debian-base" "docker/base/debian-base.Dockerfile" "docker/"
    test_image_size "debian-base" 150
    echo ""
    
    # Test Node.js base image
    log_info "Testing Node.js Base Image"
    echo "========================================="
    test_image_build "node-base" "docker/base/node-base.Dockerfile" "docker/base/"
    test_image_size "node-base" 300
    echo ""
    
    # Test Python base image
    log_info "Testing Python Base Image"
    echo "========================================="
    test_image_build "python-base" "docker/base/python-base.Dockerfile" "docker/base/"
    test_image_size "python-base" 250
    echo ""
    
    # Test example Node.js application
    log_info "Testing Example Node.js Application"
    echo "========================================="
    test_image_build "demo-node" "examples/node-app/Dockerfile" "examples/node-app/"
    test_image_size "demo-node" 350
    
    # Start demo container
    docker run -d --name demo-node-test -p 8080:8080 demo-node:test &> /dev/null
    sleep 5
    
    # Test endpoints
    test_health_check "http://localhost:8080/health" "200"
    test_health_check "http://localhost:8080/ready" "200"
    test_health_check "http://localhost:8080/metrics" "200"
    test_health_check "http://localhost:8080/" "200"
    
    # Test non-root user
    test_nonroot_user "demo-node-test"
    echo ""
    
    # Summary
    echo "========================================="
    echo "Test Summary"
    echo "========================================="
    echo "Tests Run:    $TESTS_RUN"
    echo -e "Tests Passed: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "Tests Failed: ${RED}$TESTS_FAILED${NC}"
    echo ""
    
    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "${GREEN}All tests passed!${NC}"
        exit 0
    else
        echo -e "${RED}Some tests failed!${NC}"
        exit 1
    fi
}

# Run main function
main "$@"

