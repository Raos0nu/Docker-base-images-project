#!/usr/bin/env bash
#
# Security scanning script for Docker images
#

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SEVERITY=${SEVERITY:-"HIGH,CRITICAL"}
IMAGES=("debian-base:latest" "node-base:latest" "python-base:latest" "demo-node:latest")

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

log_section() {
    echo ""
    echo -e "${BLUE}=========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}=========================================${NC}"
}

# Check if Trivy is installed
check_trivy() {
    if ! command -v trivy &> /dev/null; then
        log_error "Trivy is not installed"
        echo "Install Trivy: https://aquasecurity.github.io/trivy/"
        echo ""
        echo "Quick install:"
        echo "  macOS:   brew install trivy"
        echo "  Linux:   wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -"
        echo "           echo 'deb https://aquasecurity.github.io/trivy-repo/deb $$\(lsb_release -sc\) main' | sudo tee -a /etc/apt/sources.list.d/trivy.list"
        echo "           sudo apt-get update && sudo apt-get install trivy"
        exit 1
    fi
    log_info "Trivy version: $(trivy --version | head -n1)"
}

# Scan image with Trivy
scan_image() {
    local image=$1
    
    log_section "Scanning $image"
    
    # Check if image exists
    if ! docker image inspect "$image" &> /dev/null; then
        log_error "Image $image not found. Build it first."
        return 1
    fi
    
    # Run Trivy scan
    log_info "Running vulnerability scan..."
    trivy image \
        --severity "$SEVERITY" \
        --no-progress \
        --format table \
        "$image"
    
    echo ""
    log_info "Scan complete for $image"
}

# Scan filesystem
scan_filesystem() {
    log_section "Scanning Filesystem"
    
    log_info "Scanning project directory for misconfigurations..."
    trivy fs \
        --severity "$SEVERITY" \
        --no-progress \
        --format table \
        .
    
    echo ""
    log_info "Filesystem scan complete"
}

# Scan for secrets
scan_secrets() {
    log_section "Scanning for Secrets"
    
    log_info "Scanning for exposed secrets..."
    trivy fs \
        --scanners secret \
        --no-progress \
        --format table \
        .
    
    echo ""
    log_info "Secret scan complete"
}

# Generate SBOM (Software Bill of Materials)
generate_sbom() {
    local image=$1
    local output_dir="reports"
    
    mkdir -p "$output_dir"
    
    log_info "Generating SBOM for $image..."
    trivy image \
        --format cyclonedx \
        --output "$output_dir/sbom-$(echo $image | tr ':/' '--').json" \
        "$image"
    
    log_info "SBOM saved to $output_dir/sbom-$(echo $image | tr ':/' '--').json"
}

# Main function
main() {
    echo "========================================="
    echo "Docker Base Images - Security Scanner"
    echo "========================================="
    echo ""
    
    # Check prerequisites
    check_trivy
    
    # Parse arguments
    SCAN_TYPE=${1:-"all"}
    
    case "$SCAN_TYPE" in
        images)
            # Scan all images
            for image in "${IMAGES[@]}"; do
                scan_image "$image"
            done
            ;;
        fs|filesystem)
            # Scan filesystem
            scan_filesystem
            ;;
        secrets)
            # Scan for secrets
            scan_secrets
            ;;
        sbom)
            # Generate SBOMs
            log_section "Generating SBOMs"
            for image in "${IMAGES[@]}"; do
                generate_sbom "$image"
            done
            ;;
        all)
            # Run all scans
            for image in "${IMAGES[@]}"; do
                scan_image "$image"
            done
            scan_filesystem
            scan_secrets
            ;;
        *)
            log_error "Unknown scan type: $SCAN_TYPE"
            echo "Usage: $0 [images|filesystem|secrets|sbom|all]"
            exit 1
            ;;
    esac
    
    log_section "Security Scan Complete"
    echo -e "${GREEN}✓ All security scans completed${NC}"
    echo ""
    echo "For detailed reports, check the 'reports' directory"
}

# Run main function
main "$@"

