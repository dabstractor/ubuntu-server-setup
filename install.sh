#!/bin/bash

# Bootstrap installer for server setup
# Usage: curl -L server-setup.mulletware.io | bash
#    OR: curl -fsSL server-setup.mulletware.io -o install.sh && bash install.sh

set -e

REPO_URL="https://raw.githubusercontent.com/dabstractor/ubuntu-server-setup/main"
SETUP_SCRIPT="setup-server.sh"

echo "=== Server Setup Bootstrap ==="
echo

# Check if running on Ubuntu
if [ ! -f /etc/lsb-release ] || ! grep -q "Ubuntu" /etc/lsb-release; then
    echo "⚠ Warning: This script is designed for Ubuntu."
    if [ -t 0 ]; then
        echo "Continue? (y/N)"
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            echo "Aborted."
            exit 1
        fi
    else
        echo "Continuing anyway (non-interactive mode)..."
    fi
fi

# Check if running as root
if [ "$(id -u)" -eq 0 ]; then
    echo "Error: Please run as a regular user with sudo privileges, not as root."
    exit 1
fi

# Download setup script
echo "Downloading setup script..."
curl -fsSL "$REPO_URL/$SETUP_SCRIPT" -o "$SETUP_SCRIPT"
chmod +x "$SETUP_SCRIPT"

echo "✓ Downloaded $SETUP_SCRIPT"
echo

# Check if stdin is available (not piped)
if [ -t 0 ]; then
    # Interactive mode - run directly
    echo "Starting setup..."
    echo
    ./"$SETUP_SCRIPT"
else
    # Piped mode - instruct user
    echo "Setup script downloaded successfully!"
    echo
    echo "To run the setup, execute:"
    echo "  ./$SETUP_SCRIPT"
    echo
fi
