#!/usr/bin/env bash
#
# Dockerfile linting script
#

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if hadolint is installed
check_hadolint() {
    if ! command -v hadolint &> /dev/null; then
        log_error "hadolint is not installed"
        echo "Install hadolint: https://github.com/hadolint/hadolint"
        echo ""
        echo "Quick install:"
        echo "  macOS:   brew install hadolint"
        echo "  Linux:   wget -O /usr/local/bin/hadolint https://github.com/hadolint/hadolint/releases/download/v2.12.0/hadolint-Linux-x86_64"
        echo "           chmod +x /usr/local/bin/hadolint"
        exit 1
    fi
    log_info "hadolint version: $(hadolint --version | head -n1)"
}

# Lint Dockerfile
lint_dockerfile() {
    local dockerfile=$1
    local name=$(basename "$dockerfile")
    
    echo ""
    echo "Linting $dockerfile..."
    echo "---"
    
    if hadolint "$dockerfile"; then
        echo -e "${GREEN}✓${NC} $name passed linting"
    else
        echo -e "${RED}✗${NC} $name failed linting"
        return 1
    fi
}

# Main
main() {
    echo "========================================="
    echo "Docker Base Images - Dockerfile Linter"
    echo "========================================="
    
    check_hadolint
    
    local failed=0
    
    # Lint all Dockerfiles
    for dockerfile in docker/base/*.Dockerfile examples/*/Dockerfile; do
        if [ -f "$dockerfile" ]; then
            lint_dockerfile "$dockerfile" || ((failed++))
        fi
    done
    
    echo ""
    echo "========================================="
    if [ $failed -eq 0 ]; then
        echo -e "${GREEN}✓ All Dockerfiles passed linting${NC}"
        exit 0
    else
        echo -e "${RED}✗ $failed Dockerfile(s) failed linting${NC}"
        exit 1
    fi
}

main "$@"

