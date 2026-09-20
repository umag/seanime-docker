#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Pin the Goss version. As of v0.4.x the release assets are tarballs
# (goss_<ver>_linux_x86_64.tar.gz), not the old raw goss-linux-amd64 binary,
# so the ".../latest/download/goss-linux-amd64" URL now 404s.
GOSS_VERSION="v0.4.10"
GOSS_TARBALL="goss_${GOSS_VERSION#v}_linux_x86_64.tar.gz"
GOSS_URL="https://github.com/goss-org/goss/releases/download/${GOSS_VERSION}/${GOSS_TARBALL}"

# Download the pinned Goss release and extract the linux/amd64 binary.
# curl -f makes an HTTP error fail loudly instead of saving an error page
# as the "binary" (which would later run as a script and exit 127).
download_goss() {
    local dest="$1"
    echo "Downloading Goss ${GOSS_VERSION} (linux/amd64)..."
    curl -fL "$GOSS_URL" | tar -xzO goss > "$dest"
    chmod +x "$dest"
    echo "Downloaded Goss binary: $dest"
}

# Ensure dgoss is executable
chmod +x "$SCRIPT_DIR/dgoss"

echo "=== Setup: Goss Binary ==="
OS=$(uname -s)
GOSS_BINARY=""

if [ "$OS" == "Linux" ]; then
    if command -v goss &> /dev/null; then
        GOSS_BINARY=$(command -v goss)
        echo "Found existing Goss installation: $GOSS_BINARY"
    else
        # Download Goss if not found (e.g., on GitHub runners)
        if [ -f "$SCRIPT_DIR/goss-linux-amd64" ]; then
            GOSS_BINARY="$SCRIPT_DIR/goss-linux-amd64"
            echo "Using cached Goss binary: $GOSS_BINARY"
        else
            echo "Goss not found. Downloading Linux version of Goss..."
            download_goss "$SCRIPT_DIR/goss-linux-amd64"
            GOSS_BINARY="$SCRIPT_DIR/goss-linux-amd64"
        fi
    fi
elif [ "$OS" == "Darwin" ]; then
    if [ -f "$SCRIPT_DIR/goss-linux-amd64" ]; then
        GOSS_BINARY="$SCRIPT_DIR/goss-linux-amd64"
        echo "Using cached Goss binary: $GOSS_BINARY"
    else
        echo "Detected macOS. Downloading Linux version of Goss for container compatibility..."
        download_goss "$SCRIPT_DIR/goss-linux-amd64"
        GOSS_BINARY="$SCRIPT_DIR/goss-linux-amd64"
    fi
fi

if [ -n "$GOSS_BINARY" ]; then
    echo "$GOSS_BINARY"
else
    echo "ERROR: Could not find or download compatible Goss binary." >&2
    exit 1
fi
