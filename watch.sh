#!/bin/bash
# Script to watch for .mkd file changes and run make
# Supports macOS (fswatch) and Linux (inotifywait)
# Usage: ./watch_mkd.sh [directory]

# Set the directory to watch (default to current directory)
WATCH_DIR="${1:-.}"

echo "Watching for .mkd file changes in: $WATCH_DIR"
echo "Press Ctrl+C to stop"
echo ""

# Detect OS and check for required tool
OS="$(uname -s)"

if [[ "$OS" == "Darwin" ]]; then
    if ! command -v fswatch &> /dev/null; then
        echo "Error: fswatch is not installed"
        echo "Install it with: brew install fswatch"
        exit 1
    fi
    echo "Using fswatch (macOS)"
elif [[ "$OS" == "Linux" ]]; then
    if ! command -v inotifywait &> /dev/null; then
        echo "Error: inotifywait is not installed"
        echo "Install it with: sudo apt install inotify-tools"
        exit 1
    fi
    echo "Using inotifywait (Linux)"
else
    echo "Error: Unsupported OS: $OS"
    exit 1
fi

echo ""

run_make() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Change detected: $1"
    echo "Running make..."
    make -C "$WATCH_DIR"
    echo "---"
}

# Start watching
if [[ "$OS" == "Darwin" ]]; then
    fswatch -r "$WATCH_DIR" | while read file; do
        if [[ "$file" == *.mkd ]]; then
            run_make "$file"
        fi
    done
elif [[ "$OS" == "Linux" ]]; then
    inotifywait -m -r -e close_write,moved_to "$WATCH_DIR" --include '.*\.mkd$' |
    while read dir event file; do
        run_make "$dir$file"
    done
fi
