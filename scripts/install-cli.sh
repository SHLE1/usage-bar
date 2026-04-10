#!/bin/bash
set -e

# Install UsageBar CLI to /usr/local/bin
# This script copies the CLI binary from the app bundle to /usr/local/bin

APP_PATH="/Applications/UsageBar.app"
CLI_SOURCE="$APP_PATH/Contents/MacOS/usagebar-cli"
CLI_DEST="/usr/local/bin/usagebar"

# Verify CLI binary exists in app bundle
if [ ! -f "$CLI_SOURCE" ]; then
    echo "❌ Error: CLI binary not found at $CLI_SOURCE"
    echo "Make sure UsageBar is installed in /Applications/"
    exit 1
fi

# Create /usr/local/bin if it doesn't exist
mkdir -p /usr/local/bin

# Copy CLI binary to /usr/local/bin
cp "$CLI_SOURCE" "$CLI_DEST"
chmod +x "$CLI_DEST"

echo "✅ CLI installed successfully to $CLI_DEST"
echo "Run 'usagebar --help' to see available commands"
