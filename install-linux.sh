#!/usr/bin/env bash
# install-linux.sh — brained-flow installer for Linux
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo ""
echo "  brained-flow installer (Linux)"
echo "  ─────────────────────────────────────────"
echo ""

# ── 1. Cowork skills directory ────────────────────────────────────────────────

DEFAULT_SKILLS="${XDG_CONFIG_HOME:-$HOME/.config}/Claude/skills"
echo "  [1/3] Cowork skills directory"
echo "        Default: $DEFAULT_SKILLS"
read -rp "        Press Enter to use default, or type a path: " INPUT_SKILLS
SKILLS_DEST="${INPUT_SKILLS:-$DEFAULT_SKILLS}"

# ── 2. Claude Code commands directory ────────────────────────────────────────

DEFAULT_COMMANDS="$(pwd)/.claude/commands"
echo ""
echo "  [2/3] Claude Code commands directory"
echo "        Default: $DEFAULT_COMMANDS  (current folder)"
read -rp "        Press Enter to use default, or type a path: " INPUT_COMMANDS
COMMANDS_DEST="${INPUT_COMMANDS:-$DEFAULT_COMMANDS}"

# ── 3. brain/ wiki directory ──────────────────────────────────────────────────

echo ""
echo "  [3/3] brain/ wiki directory"
echo "        Example: ~/brain  or  ~/Documents/brain"
read -rp "        Path (leave blank to skip wiki-sync setup): " BRAIN_DIR

# ── Summary ───────────────────────────────────────────────────────────────────

echo ""
echo "  ─────────────────────────────────────────"
echo "  Installing to:"
echo "    Skills   → $SKILLS_DEST"
echo "    Commands → $COMMANDS_DEST"
[ -n "$BRAIN_DIR" ] && echo "    brain/   → $BRAIN_DIR"
echo ""
read -rp "  Proceed? (y/n): " CONFIRM
[[ "$CONFIRM" =~ ^[Yy]$ ]] || { echo "  Cancelled."; exit 0; }

# ── Install skills ────────────────────────────────────────────────────────────

echo ""
echo "  Installing Cowork skills..."
for SKILL in brain-sync wiki-setup brain-plan brain-run; do
    SRC="$SCRIPT_DIR/skills/$SKILL"
    DST="$SKILLS_DEST/$SKILL"
    rm -rf "$DST"
    mkdir -p "$SKILLS_DEST"
    cp -r "$SRC" "$DST"
    echo "    OK  $SKILL"
done

# ── Install commands ──────────────────────────────────────────────────────────

echo ""
echo "  Installing slash commands..."
mkdir -p "$COMMANDS_DEST"
for CMD in brain-plan.md brain-run.md; do
    cp "$SCRIPT_DIR/commands/$CMD" "$COMMANDS_DEST/$CMD"
    echo "    OK  /${CMD%.md}"
done

# ── Wiki sync setup ───────────────────────────────────────────────────────────

if [ -n "$BRAIN_DIR" ]; then
    echo ""
    echo "  Checking wiki sync scripts in brain/..."
    MISSING=()
    for S in wiki-push.py wiki-pull.py wiki-watch.sh; do
        [ -f "$BRAIN_DIR/$S" ] || MISSING+=("$S")
    done
    if [ ${#MISSING[@]} -gt 0 ]; then
        echo "    Missing: ${MISSING[*]}"
        echo "    → Ask Claude: 'Help me set up wiki sync' (uses wiki-setup skill)"
    else
        echo "    All sync scripts present."
    fi

    # Copy wiki-watch.sh to brain/ if available
    if [ -f "$SCRIPT_DIR/wiki-watch.sh" ] && [ ! -f "$BRAIN_DIR/wiki-watch.sh" ]; then
        cp "$SCRIPT_DIR/wiki-watch.sh" "$BRAIN_DIR/wiki-watch.sh"
        chmod +x "$BRAIN_DIR/wiki-watch.sh"
        echo "    Copied wiki-watch.sh to $BRAIN_DIR"
    fi

    KEY_FILE="$HOME/.claude/claude-ai-session.key"
    if [ ! -f "$KEY_FILE" ]; then
        echo ""
        echo "  Session key not found at $KEY_FILE"
        echo "  → Get it from claude.ai: F12 > Application > Cookies > sessionKey"
        echo "  → Save: echo 'YOUR_KEY' > $KEY_FILE"
    fi

    # Check inotifywait
    if ! command -v inotifywait &>/dev/null; then
        echo ""
        echo "  inotify-tools not found — required for wiki-watch.sh"
        echo "  → Install: sudo apt install inotify-tools"
        echo "             sudo dnf install inotify-tools"
        echo "             sudo pacman -S inotify-tools"
    fi
fi


# ── Naming warning ───────────────────────────────────────────────────────────

echo ""
echo "  ─────────────────────────────────────────"
echo "  IMPORTANT: Project name must match exactly in all three places:"
echo "    1. claude.ai       -> Project name in the sidebar"
echo "    2. Claude Cowork   -> Folder/project name in Cowork"
echo "    3. wiki-push.py    -> PROJECT_NAME variable in the script"
echo "  A mismatch causes silent sync failures."
# ── Done ──────────────────────────────────────────────────────────────────────

echo ""
echo "  ─────────────────────────────────────────"
echo "  Done!"
echo ""
echo "  Next steps:"
echo "    1. Restart Claude Cowork to load skills"
echo "    2. Ask Claude: 'Help me set up wiki sync' to configure brain/"
echo "    3. Start planning: 'brain-plan: <your task>'"
echo ""
