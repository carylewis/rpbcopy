#!/usr/bin/env bash
#
# install.sh — Install rpbcopy on macOS or Linux
#
# Usage: ./install.sh

set -euo pipefail

INSTALL_DIR="${INSTALL_DIR:-/usr/local/bin}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "rpbcopy installer"
echo "================="
echo ""

# Check for socat
if ! command -v socat &>/dev/null; then
    echo "Warning: socat is not installed."
    if [[ "$(uname)" == "Darwin" ]]; then
        echo "  Install it with: brew install socat"
    else
        echo "  Install it with: sudo apt install socat  (or yum install socat)"
    fi
    echo ""
fi

OS="$(uname)"

install_file() {
    local src="$1" dst="$2"
    if [[ -w "$(dirname "$dst")" ]]; then
        cp "$src" "$dst"
    else
        echo "  (requires sudo)"
        sudo cp "$src" "$dst"
    fi
    chmod +x "$dst"
}

if [[ "$OS" == "Darwin" ]]; then
    echo "Detected: macOS"
    echo ""

    # Install all three scripts
    echo "Installing scripts to $INSTALL_DIR..."
    install_file "$SCRIPT_DIR/bin/rpbcopy-listen" "$INSTALL_DIR/rpbcopy-listen"
    install_file "$SCRIPT_DIR/bin/rpbcopy" "$INSTALL_DIR/rpbcopy"
    install_file "$SCRIPT_DIR/bin/rpbpaste" "$INSTALL_DIR/rpbpaste"
    echo "  installed: rpbcopy-listen, rpbcopy, rpbpaste"
    echo ""

    # Offer launchd setup
    read -rp "Set up rpbcopy-listen to start automatically on login? [y/N] " setup_launchd
    if [[ "$setup_launchd" =~ ^[Yy] ]]; then
        PLIST_SRC="$SCRIPT_DIR/launchd/com.rpbcopy.listener.plist"
        PLIST_DST="$HOME/Library/LaunchAgents/com.rpbcopy.listener.plist"
        mkdir -p "$HOME/Library/LaunchAgents"
        mkdir -p "$HOME/Library/Logs"

        # Update the plist with actual paths
        sed -e "s|/usr/local/bin/rpbcopy-listen|$INSTALL_DIR/rpbcopy-listen|g" \
            -e "s|/tmp/rpbcopy.log|$HOME/Library/Logs/rpbcopy.log|g" \
            "$PLIST_SRC" > "$PLIST_DST"

        launchctl unload "$PLIST_DST" 2>/dev/null || true
        launchctl load -w "$PLIST_DST"
        echo "  launchd service installed and started"
        echo "  logs: ~/Library/Logs/rpbcopy.log"
    fi

elif [[ "$OS" == "Linux" ]]; then
    echo "Detected: Linux"
    echo ""

    # On Linux, only the remote-side scripts are needed
    echo "Installing remote scripts to $INSTALL_DIR..."
    install_file "$SCRIPT_DIR/bin/rpbcopy" "$INSTALL_DIR/rpbcopy"
    install_file "$SCRIPT_DIR/bin/rpbpaste" "$INSTALL_DIR/rpbpaste"
    echo "  installed: rpbcopy, rpbpaste"

else
    echo "Unsupported OS: $OS" >&2
    exit 1
fi

echo ""
echo "Done! Run 'rpbcopy --help' to get started."
