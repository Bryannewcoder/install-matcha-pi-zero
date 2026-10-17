#!/bin/bash
# ============================================================
#  install-matcha.sh
#  Installs the Matcha terminal email client on a
#  Raspberry Pi Zero (32-bit ARMv6, linux/arm GOARCH=arm GOARM=6)
#
#  Usage:
#    chmod +x install-matcha.sh
#    ./install-matcha.sh
# ============================================================

set -euo pipefail

# ---------- Colour helpers ----------
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
info()    { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }

# ---------- Config ----------
REPO="https://github.com/floatpane/matcha.git"
INSTALL_DIR="$HOME/.local/bin"
BUILD_DIR="/tmp/matcha-build"
GO_VERSION="1.22.4"                         # minimum Go version known to work
GO_TARBALL="go${GO_VERSION}.linux-armv6l.tar.gz"
GO_URL="https://go.dev/dl/${GO_TARBALL}"
GO_INSTALL_DIR="/usr/local/go"

# ---------- Verify architecture ----------
ARCH=$(uname -m)
info "Detected architecture: $ARCH"
if [[ "$ARCH" != "armv6l" && "$ARCH" != "armv7l" ]]; then
    warn "This script targets Raspberry Pi Zero (ARMv6). Your arch is '$ARCH'."
    read -rp "Continue anyway? [y/N] " ans
    [[ "$ans" =~ ^[Yy]$ ]] || exit 0
fi

# ---------- Update package lists ----------
info "Updating package lists..."
sudo apt-get update -qq

# ---------- Install build dependencies ----------
info "Installing build dependencies (git, gcc, make)..."
sudo apt-get install -y --no-install-recommends \
    git \
    gcc \
    make \
    ca-certificates \
    curl

# ---------- Install / verify Go ----------
if command -v go &>/dev/null; then
    INSTALLED_GO=$(go version | awk '{print $3}' | sed 's/go//')
    info "Go already installed: $INSTALLED_GO"
    # Simple semver check: require >= 1.21
    MAJOR=$(echo "$INSTALLED_GO" | cut -d. -f1)
    MINOR=$(echo "$INSTALLED_GO" | cut -d. -f2)
    if [[ "$MAJOR" -lt 1 ]] || { [[ "$MAJOR" -eq 1 ]] && [[ "$MINOR" -lt 21 ]]; }; then
        warn "Go $INSTALLED_GO is too old (need >= 1.21). Installing $GO_VERSION..."
        INSTALL_GO=true
    else
        info "Go version is sufficient."
        INSTALL_GO=false
    fi
else
    info "Go not found. Installing Go $GO_VERSION for ARMv6..."
    INSTALL_GO=true
fi

if [[ "$INSTALL_GO" == true ]]; then
    info "Downloading $GO_TARBALL ..."
    curl -fSL "$GO_URL" -o "/tmp/${GO_TARBALL}"

    info "Extracting Go to $GO_INSTALL_DIR ..."
    sudo rm -rf "$GO_INSTALL_DIR"
    sudo tar -C /usr/local -xzf "/tmp/${GO_TARBALL}"
    rm -f "/tmp/${GO_TARBALL}"

    # Add Go to PATH for this session
    export PATH="$GO_INSTALL_DIR/bin:$PATH"

    # Persist PATH in shell config files
    for RC in "$HOME/.bashrc" "$HOME/.profile"; do
        if [[ -f "$RC" ]] && ! grep -q 'go/bin' "$RC"; then
            echo 'export PATH="/usr/local/go/bin:$PATH"' >> "$RC"
            info "Added Go to PATH in $RC"
        fi
    done
fi

export PATH="$GO_INSTALL_DIR/bin:$PATH"
go version || error "Go installation failed."

# ---------- Clone matcha ----------
info "Cloning matcha repository..."
rm -rf "$BUILD_DIR"
git clone --depth=1 "$REPO" "$BUILD_DIR"
cd "$BUILD_DIR"

# ---------- Build for linux/arm (32-bit ARMv6) ----------
info "Building matcha for linux/arm (ARMv6)..."
mkdir -p "$INSTALL_DIR"

GOOS=linux GOARCH=arm GOARM=6 go build -ldflags="-s -w" -o "$INSTALL_DIR/matcha" .

info "Binary written to $INSTALL_DIR/matcha"

# ---------- Add INSTALL_DIR to PATH if needed ----------
if ! echo "$PATH" | grep -q "$INSTALL_DIR"; then
    for RC in "$HOME/.bashrc" "$HOME/.profile"; do
        if [[ -f "$RC" ]] && ! grep -q "$INSTALL_DIR" "$RC"; then
            echo "export PATH=\"$INSTALL_DIR:\$PATH\"" >> "$RC"
            info "Added $INSTALL_DIR to PATH in $RC"
        fi
    done
    export PATH="$INSTALL_DIR:$PATH"
fi

# ---------- Clean up ----------
info "Cleaning up build directory..."
rm -rf "$BUILD_DIR"

# ---------- Verify installation ----------
if command -v matcha &>/dev/null; then
    info "✅  Matcha installed successfully!"
    matcha --version 2>/dev/null || true
else
    # Binary exists but may not be in current PATH yet
    if [[ -x "$INSTALL_DIR/matcha" ]]; then
        info "✅  Matcha installed at $INSTALL_DIR/matcha"
        info "    Run: source ~/.bashrc  (or open a new terminal) then type: matcha"
    else
        error "Installation failed — binary not found."
    fi
fi

echo ""
echo -e "${GREEN}=== Next steps ===${NC}"
echo "  1. Reload your shell:   source ~/.bashrc"
echo "  2. Launch matcha:       matcha"
echo "  3. Add your email account when prompted (IMAP/SMTP credentials)."
echo "  4. Config file lives at: ~/.config/matcha/config.json"
echo ""
echo "  Keyboard shortcuts inside matcha:"
echo "    j/k      — navigate up/down"
echo "    Enter    — open email"
echo "    Tab      — switch accounts"
echo "    r        — refresh inbox"
echo "    q / Esc  — go back / quit"
