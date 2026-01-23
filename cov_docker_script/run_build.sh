#!/usr/bin/env bash
set -e

################################################################################
# GMock Broadband Build Script
# Clones gmock-broadband, copies build scripts, and runs common_external_build
# Usage: ./run_build.sh
################################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NATIVE_COMPONENT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
GMOCK_REPO_URL="https://github.com/rdkcentral/gmock-broadband"
GMOCK_DIR="$NATIVE_COMPONENT_DIR/gmock-broadband"
REQUIRED_SCRIPTS=("build_native.sh" "common_build_utils.sh" "common_external_build.sh" "setup_dependencies.sh")

# Basic logging functions
log() { echo "[INFO] $*"; }
ok() { echo "[OK] $*"; }
err() { echo "[ERROR] $*" >&2; }
warn() { echo "[WARN] $*"; }

echo ""
echo "===== GMock Broadband Build Pipeline ====="
echo ""

# Step 1: Clone gmock-broadband
if [[ -d "$GMOCK_DIR" ]]; then
    log "gmock-broadband already exists at $GMOCK_DIR, skipping clone"
else
    log "Cloning gmock-broadband (feature/native_build) to $GMOCK_DIR"
    cd "$NATIVE_COMPONENT_DIR"
    git clone -b feature/native_build "$GMOCK_REPO_URL" || { err "Clone failed"; exit 1; }
    ok "Repository cloned"
fi

# Step 2: Verify required scripts
[[ ! -d "$GMOCK_DIR/cov_docker_script" ]] && { err "cov_docker_script not found in gmock-broadband"; exit 1; }

log "Verifying required scripts..."
MISSING=()
for script in "${REQUIRED_SCRIPTS[@]}"; do
    [[ -f "$GMOCK_DIR/cov_docker_script/$script" ]] || MISSING+=("$script")
done

if [[ ${#MISSING[@]} -gt 0 ]]; then
    err "Missing scripts: ${MISSING[*]}"
    exit 1
fi
ok "All required scripts found"

# Step 3: Copy all .sh files (except this script)
log "Copying *.sh files from gmock-broadband to $SCRIPT_DIR"
THIS_SCRIPT=$(basename "${BASH_SOURCE[0]}")
set +e
COPIED=0

for file in "$GMOCK_DIR/cov_docker_script"/*.sh; do
    [[ -f "$file" ]] || continue
    filename=$(basename "$file")
    [[ "$filename" == "$THIS_SCRIPT" ]] && continue
    cp -f "$file" "$SCRIPT_DIR/" 2>/dev/null && ((COPIED++))
done
set -e

chmod +x "$SCRIPT_DIR"/*.sh 2>/dev/null || true
ok "Copied $COPIED script(s)"

# Cleanup: Remove gmock-broadband directory
log "Cleaning up gmock-broadband directory..."
rm -rf "$GMOCK_DIR"
ok "Cleanup completed"

# Step 4: Run build
log "Running common_external_build.sh..."
[[ ! -f "$SCRIPT_DIR/common_external_build.sh" ]] && { err "common_external_build.sh not found"; exit 1; }

cd "$NATIVE_COMPONENT_DIR"
./cov_docker_script/common_external_build.sh

echo ""
ok "GMock Broadband build completed successfully!"
echo ""
