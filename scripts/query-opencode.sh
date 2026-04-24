#!/bin/bash
# Query OpenCode usage statistics
# Uses: opencode stats command
# Data source: Local session data

set -e

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/bin-discovery.sh"

OPENCODE_BIN="$(find_executable_binary \
    "opencode" \
    "/opt/homebrew/bin/opencode" \
    "/usr/local/bin/opencode" \
    "$HOME/.opencode/bin/opencode" \
    "$HOME/.local/bin/opencode" \
    "/usr/bin/opencode" || true)"
if [[ -z "$OPENCODE_BIN" ]]; then
    echo "Error: OpenCode CLI not found. Please ensure 'opencode' is in your PATH." >&2
    echo "Searched: PATH, login shell PATH, and common installation locations." >&2
    exit 1
fi

echo "Using OpenCode binary: $OPENCODE_BIN"

# Default to last 30 days
DAYS="${1:-30}"

echo "=== OpenCode Usage (Last $DAYS Days) ==="
echo ""

# Run opencode stats with models breakdown
"$OPENCODE_BIN" stats --days "$DAYS" --models 10 --tools 10 2>&1

# Also show per-project breakdown if requested
if [[ "$2" == "--projects" ]]; then
    echo ""
    echo "=== Per-Project Breakdown ==="

    # Get list of recent projects from sessions
    SESSIONS_DIR="$HOME/.local/share/opencode/sessions"
    if [[ -d "$SESSIONS_DIR" ]]; then
        # Find unique project paths from recent sessions
        find "$SESSIONS_DIR" -name "*.json" -mtime -"$DAYS" -exec jq -r '.cwd // empty' {} \; 2>/dev/null | \
            sort | uniq -c | sort -rn | head -10
    fi
fi
