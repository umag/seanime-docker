#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Ensure dgoss is executable
chmod +x "$SCRIPT_DIR/dgoss"

echo "=== Setup: Goss Binary ==="
OS=$(uname -s)
GOSS_BINARY=""

if [ "$OS" == "Linux" ]; then
    if command -v goss &> /dev/null; then
        GOSS_BINARY=$(command -v goss)
    fi
elif [ "$OS" == "Darwin" ]; then
    if [ -f "$SCRIPT_DIR/goss-linux-amd64" ]; then
        GOSS_BINARY="$SCRIPT_DIR/goss-linux-amd64"
    else
        echo "Detected macOS. Downloading Linux version of Goss for container compatibility..."
        curl -L https://github.com/goss-org/goss/releases/latest/download/goss-linux-amd64 -o "$SCRIPT_DIR/goss-linux-amd64"
        chmod +x "$SCRIPT_DIR/goss-linux-amd64"
        GOSS_BINARY="$SCRIPT_DIR/goss-linux-amd64"
    fi
fi

if [ -n "$GOSS_BINARY" ]; then
    echo "$GOSS_BINARY"
else
    echo "ERROR: Could not find or download compatible Goss binary." >&2
    exit 1
fi
