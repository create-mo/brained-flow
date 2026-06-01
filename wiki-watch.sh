#!/usr/bin/env bash
# wiki-watch.sh — cross-platform file watcher for brain/ → claude.ai sync
# macOS:  requires fswatch  (brew install fswatch)
# Linux:  requires inotify-tools  (apt/dnf/pacman install inotify-tools)
#
# Usage: ./wiki-watch.sh [brain_dir]
#   brain_dir defaults to current directory

BRAIN_DIR="${1:-$(pwd)}"
DEBOUNCE=5  # seconds

if [ ! -d "$BRAIN_DIR" ]; then
    echo "Error: directory not found: $BRAIN_DIR"
    exit 1
fi

echo "  wiki-watch starting..."
echo "  Watching: $BRAIN_DIR"
echo "  Debounce: ${DEBOUNCE}s"
echo "  Press Ctrl+C to stop."
echo ""

run_push() {
    echo "  [$(date '+%H:%M:%S')] Change detected — pushing..."
    python3 "$BRAIN_DIR/wiki-push.py" && echo "  [$(date '+%H:%M:%S')] Push OK" || echo "  [$(date '+%H:%M:%S')] Push failed"
}

OS="$(uname -s)"

if [ "$OS" = "Darwin" ]; then
    # macOS — fswatch
    if ! command -v fswatch &>/dev/null; then
        echo "Error: fswatch not found. Install with: brew install fswatch"
        exit 1
    fi
    LAST=0
    fswatch -r --event=Updated --event=Created --event=Removed \
            --exclude='\.git' --exclude='\.DS_Store' \
            "$BRAIN_DIR" | while read -r event; do
        NOW=$(date +%s)
        if (( NOW - LAST >= DEBOUNCE )); then
            LAST=$NOW
            run_push
        fi
    done

elif [ "$OS" = "Linux" ]; then
    # Linux — inotifywait
    if ! command -v inotifywait &>/dev/null; then
        echo "Error: inotifywait not found. Install with: sudo apt install inotify-tools"
        exit 1
    fi
    PENDING=0
    while true; do
        inotifywait -r -e modify,create,delete,move \
                    --exclude '\.git' \
                    -q "$BRAIN_DIR" &>/dev/null
        PENDING=1
        sleep "$DEBOUNCE"
        if [ "$PENDING" -eq 1 ]; then
            PENDING=0
            run_push
        fi
    done

else
    echo "Unsupported OS: $OS"
    echo "Use wiki-watch.ps1 on Windows."
    exit 1
fi
