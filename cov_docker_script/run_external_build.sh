#!/usr/bin/env bash
set -e

################################################################################
# External Build Wrapper Script
# Verifies build tools and runs common_external_build.sh
# Usage: ./run_external_build.sh
# Note: run_setup_dependencies.sh should be executed first
################################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NATIVE_COMPONENT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_TOOLS_DIR="$NATIVE_COMPONENT_DIR/build_tools_workflows"

# Basic logging functions
log() { echo "[INFO] $*"; }
ok() { echo "[OK] $*"; }
err() { echo "[ERROR] $*" >&2; }

echo ""
echo "===== External Build Pipeline ====="
echo ""

# Verify build_tools_workflows exists (should be cloned by run_setup_dependencies.sh)
if [[ ! -d "$BUILD_TOOLS_DIR" ]]; then
    err "build_tools_workflows directory not found. Please run run_setup_dependencies.sh first."
    exit 1
fi

if [[ ! -f "$BUILD_TOOLS_DIR/cov_docker_script/common_external_build.sh" ]]; then
    err "common_external_build.sh not found in build_tools_workflows. Please run run_setup_dependencies.sh first."
    exit 1
fi

log "Build script found, proceeding with build..."

# Run common_external_build.sh from build_tools_workflows
echo ""
log "Running common_external_build.sh from build_tools_workflows..."
cd "$NATIVE_COMPONENT_DIR"
"$BUILD_TOOLS_DIR/cov_docker_script/common_external_build.sh"

echo ""
ok "External build completed successfully!"

echo ""
