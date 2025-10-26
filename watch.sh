#!/bin/bash

# Script to watch for .mkd file changes and run make (macOS version)
# Usage: ./watch_mkd.sh [directory]

# Set the directory to watch (default to current directory)
WATCH_DIR="${1:-.}"

echo "Watching for .mkd file changes in: $WATCH_DIR"
echo "Press Ctrl+C to stop"
echo ""

# Check if fswatch is available
if ! command -v fswatch &> /dev/null; then
    echo "Error: fswatch is not installed"
    echo "Install it with: brew install fswatch"
    exit 1
fi

# Watch for changes and filter for .mkd files
fswatch -r "$WATCH_DIR" | while read file; do
    # Check if the file has .mkd extension
    if [[ "$file" == *.mkd ]]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Change detected: $file"
        echo "Running make..."
        make
        echo "---"
    fi
done

