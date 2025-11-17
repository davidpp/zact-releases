#!/bin/bash
# install.sh - Install ZACT binary for macOS
# Usage: curl -fsSL https://raw.githubusercontent.com/USERNAME/zact-releases/main/install.sh | bash

set -euo pipefail

# Configuration
REPO="${ZACT_REPO:-davidpp/zact-releases}"
BINARY_NAME="zact"
# Default to /usr/local/bin (already in PATH, may require sudo)
INSTALL_DIR="${INSTALL_DIR:-/usr/local/bin}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Helper functions
error() {
  echo -e "${RED}Error: $1${NC}" >&2
  exit 1
}

info() {
  echo -e "${GREEN}$1${NC}" >&2
}

warn() {
  echo -e "${YELLOW}$1${NC}" >&2
}

step() {
  echo -e "${BLUE}▶ $1${NC}" >&2
}

# Detect OS
detect_os() {
  case "$(uname -s)" in
    Darwin*)
      echo "macos"
      ;;
    Linux*)
      error "Linux support coming soon. For now, download manually from:\n  https://github.com/${REPO}/releases/latest"
      ;;
    MINGW*|MSYS*|CYGWIN*)
      error "Windows support coming soon. For now, download manually from:\n  https://github.com/${REPO}/releases/latest"
      ;;
    *)
      error "Unsupported operating system: $(uname -s)\n  Supported: macOS"
      ;;
  esac
}

# Detect architecture
detect_arch() {
  local machine=$(uname -m)
  case "$machine" in
    x86_64)
      echo "x86_64"
      ;;
    arm64|aarch64)
      echo "arm64"
      ;;
    *)
      error "Unsupported architecture: $machine\n  Supported: x86_64 (Intel), arm64 (Apple Silicon)"
      ;;
  esac
}

# Get latest release version from GitHub
get_latest_version() {
  local version

  step "Fetching latest version..."

  version=$(curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest" 2>/dev/null | \
    grep '"tag_name":' | \
    sed -E 's/.*"([^"]+)".*/\1/' || echo "")

  if [ -z "$version" ]; then
    error "Failed to fetch latest release version\n  Check if repository exists: https://github.com/${REPO}"
  fi

  echo "$version"
}

# Download and verify binary
download_binary() {
  local version="$1"
  local os="$2"
  local arch="$3"
  local asset_name="${BINARY_NAME}-${os}-${arch}.tar.gz"
  local download_url="https://github.com/${REPO}/releases/download/${version}/${asset_name}"
  local tmp_dir=$(mktemp -d)

  step "Downloading ${BINARY_NAME} ${version} for ${os}-${arch}..."

  # Download binary tarball
  if ! curl -fsSL "$download_url" -o "${tmp_dir}/${asset_name}" 2>/dev/null; then
    rm -rf "$tmp_dir"
    error "Failed to download binary from:\n  ${download_url}\n\n  Please check if the release exists:\n  https://github.com/${REPO}/releases"
  fi

  info "✓ Downloaded ${asset_name}"

  # Extract binary
  step "Extracting archive..."
  if ! tar -xzf "${tmp_dir}/${asset_name}" -C "$tmp_dir" 2>/dev/null; then
    rm -rf "$tmp_dir"
    error "Failed to extract archive"
  fi

  info "✓ Extracted successfully"

  echo "$tmp_dir"
}

# Install binary to system
install_binary() {
  local tmp_dir="$1"
  local os="$2"
  local arch="$3"
  local binary_path="${tmp_dir}/${BINARY_NAME}-${os}-${arch}"

  # Verify extracted binary exists
  if [ ! -f "$binary_path" ]; then
    rm -rf "$tmp_dir"
    error "Binary not found after extraction: $binary_path"
  fi

  step "Installing to ${INSTALL_DIR}..."

  # Check if install directory exists and create if needed
  if [ ! -d "$INSTALL_DIR" ]; then
    info "Creating ${INSTALL_DIR}..."
    # Try without sudo first (for user directories)
    if ! mkdir -p "$INSTALL_DIR" 2>/dev/null; then
      # If that fails, try with sudo (for system directories)
      warn "Administrator privileges required to create ${INSTALL_DIR}"
      if ! sudo mkdir -p "$INSTALL_DIR" 2>/dev/null; then
        rm -rf "$tmp_dir"
        error "Failed to create install directory: ${INSTALL_DIR}"
      fi
    fi
  fi

  # Install binary (with or without sudo depending on permissions)
  if [ -w "$INSTALL_DIR" ]; then
    # Can write without sudo
    if ! install -m 755 "$binary_path" "${INSTALL_DIR}/${BINARY_NAME}" 2>/dev/null; then
      rm -rf "$tmp_dir"
      error "Failed to install binary to ${INSTALL_DIR}"
    fi
  else
    # Need sudo for system directories
    warn "Administrator privileges required for ${INSTALL_DIR}"
    if ! sudo install -m 755 "$binary_path" "${INSTALL_DIR}/${BINARY_NAME}" 2>/dev/null; then
      rm -rf "$tmp_dir"
      error "Failed to install binary to ${INSTALL_DIR}"
    fi
  fi

  info "✓ Installed to ${INSTALL_DIR}/${BINARY_NAME}"

  # Cleanup
  rm -rf "$tmp_dir"
}

# Verify installation
verify_installation() {
  step "Verifying installation..."

  if ! command -v "$BINARY_NAME" &> /dev/null; then
    warn "Installation succeeded, but ${BINARY_NAME} not found in PATH"
    warn "You may need to add ${INSTALL_DIR} to your PATH:"
    echo ""
    echo "  export PATH=\"${INSTALL_DIR}:\$PATH\""
    echo ""
    warn "Or run directly: ${INSTALL_DIR}/${BINARY_NAME}"
    return
  fi

  local installed_version
  if installed_version=$("$BINARY_NAME" --version 2>&1); then
    info "✓ ${BINARY_NAME} is ready!"
    info "  Version: ${installed_version}"
    info "  Location: $(command -v $BINARY_NAME)"
  else
    info "✓ ${BINARY_NAME} installed at: $(command -v $BINARY_NAME)"
  fi
}

# Main installation flow
main() {
  echo ""
  info "========================================="
  info "   ZACT Installation Script"
  info "========================================="
  echo ""

  # Check for required tools
  if ! command -v curl &> /dev/null; then
    error "curl is required but not installed"
  fi

  if ! command -v tar &> /dev/null; then
    error "tar is required but not installed"
  fi

  # Detect system
  local os=$(detect_os)
  local arch=$(detect_arch)
  info "Detected system: ${os}-${arch}"
  echo ""

  # Get latest version
  local version=$(get_latest_version)
  info "Latest version: ${version}"
  echo ""

  # Download binary
  local tmp_dir=$(download_binary "$version" "$os" "$arch")

  # Install binary
  install_binary "$tmp_dir" "$os" "$arch"
  echo ""

  # Verify installation
  verify_installation

  echo ""
  info "========================================="
  info "   Installation Complete!"
  info "========================================="
  echo ""
  info "Get started:"
  echo "  ${BINARY_NAME} --help"
  echo ""
  info "Report issues:"
  echo "  https://github.com/${REPO}/issues"
  echo ""
}

# Run main function
main "$@"
