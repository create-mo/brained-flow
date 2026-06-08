#!/usr/bin/env bash
# tests/test_install.sh — integration tests for brained-flow installers
# Run from repo root: bash tests/test_install.sh
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PASS=0; FAIL=0

ok()   { echo "  ✓  $1"; PASS=$((PASS + 1)); }
fail() { echo "  ✗  $1"; FAIL=$((FAIL + 1)); }

assert_file()  { [ -f "$1" ] && ok "$2" || fail "$2 — missing: $1"; }
assert_dir()   { [ -d "$1" ] && ok "$2" || fail "$2 — missing: $1"; }
assert_exec()  { [ -x "$1" ] && ok "$2" || fail "$2 — not executable: $1"; }
assert_contains() { grep -q "$2" "$1" && ok "$3" || fail "$3 — pattern not found in $1"; }

echo ""
echo "  brained-flow test suite"
echo "  ─────────────────────────────────────────"

# ── Repo structure ────────────────────────────────────────────────────────────
echo ""
echo "  [1] Repo structure"

assert_file "$REPO_DIR/install.ps1"          "install.ps1 exists"
assert_file "$REPO_DIR/install-macos.sh"     "install-macos.sh exists"
assert_file "$REPO_DIR/install-linux.sh"     "install-linux.sh exists"
assert_file "$REPO_DIR/wiki-watch.sh"        "wiki-watch.sh exists"
assert_file "$REPO_DIR/.gitignore"           ".gitignore exists"
assert_file "$REPO_DIR/README.md"            "README.md exists"
assert_file "$REPO_DIR/LICENSE"              "LICENSE exists"

assert_dir "$REPO_DIR/skills/brain-sync"    "skill: brain-sync"
assert_dir "$REPO_DIR/skills/wiki-setup"    "skill: wiki-setup"
assert_dir "$REPO_DIR/skills/brain-plan"    "skill: brain-plan"
assert_dir "$REPO_DIR/skills/brain-run"     "skill: brain-run"
assert_dir "$REPO_DIR/skills/ui-tokens"     "skill: ui-tokens"

assert_file "$REPO_DIR/skills/brain-sync/SKILL.md"  "brain-sync SKILL.md"
assert_file "$REPO_DIR/skills/wiki-setup/SKILL.md"  "wiki-setup SKILL.md"
assert_file "$REPO_DIR/skills/brain-plan/SKILL.md"  "brain-plan SKILL.md"
assert_file "$REPO_DIR/skills/brain-run/SKILL.md"   "brain-run SKILL.md"
assert_file "$REPO_DIR/skills/ui-tokens/SKILL.md"   "ui-tokens SKILL.md"

assert_file "$REPO_DIR/commands/brain-plan.md"  "command: brain-plan.md"
assert_file "$REPO_DIR/commands/brain-run.md"   "command: brain-run.md"
assert_file "$REPO_DIR/commands/wiki.md"        "command: wiki.md"

assert_file "$REPO_DIR/skills/brain-sync/v2-browser-bridge/bridge.js"  "v2 bridge: bridge.js"
assert_file "$REPO_DIR/skills/brain-sync/v2-browser-bridge/sync.py"    "v2 bridge: sync.py"
assert_file "$REPO_DIR/skills/brain-sync/v2-browser-bridge/RUNBOOK.md" "v2 bridge: RUNBOOK.md"

# ── Security: no personal data ────────────────────────────────────────────────
echo ""
echo "  [2] No personal data in repo"

check_no_pattern() {
    local pattern="$1" label="$2"
    if grep -rq "$pattern" "$REPO_DIR/skills" "$REPO_DIR/commands" "$REPO_DIR/README.md" 2>/dev/null; then
        fail "$label — pattern found: $pattern"
    else
        ok "$label"
    fi
}

check_no_pattern "019e7061"        "no hardcoded Project ID (VPSS)"
check_no_pattern "019e7085"        "no hardcoded Project ID (new claude abilities)"
check_no_pattern "019d4308"        "no hardcoded Project ID (mostik)"
check_no_pattern "fc29990a"        "no hardcoded ORG_ID"
check_no_pattern "ВОблако"         "no personal cloud path"
check_no_pattern "vitejs-vite-6hpxonsb" "no personal project slug"
check_no_pattern "Users\\\\user"   "no Windows username path"

# ── .gitignore ────────────────────────────────────────────────────────────────
echo ""
echo "  [3] .gitignore"
assert_contains "$REPO_DIR/.gitignore" "\.key"                  ".gitignore covers *.key"
assert_contains "$REPO_DIR/.gitignore" "publish-to-github"      ".gitignore covers publish script"
assert_contains "$REPO_DIR/.gitignore" "__pycache__"            ".gitignore covers __pycache__"

# ── Shell scripts are valid bash ──────────────────────────────────────────────
echo ""
echo "  [4] Shell script syntax"
for f in install-macos.sh install-linux.sh wiki-watch.sh; do
    if bash -n "$REPO_DIR/$f" 2>/dev/null; then
        ok "$f syntax OK"
    else
        fail "$f has syntax errors"
    fi
done

# ── SKILL.md frontmatter ──────────────────────────────────────────────────────
echo ""
echo "  [5] SKILL.md frontmatter"
for skill in brain-sync wiki-setup brain-plan brain-run ui-tokens; do
    f="$REPO_DIR/skills/$skill/SKILL.md"
    if head -1 "$f" | grep -q "^---"; then
        ok "$skill SKILL.md has frontmatter"
    else
        fail "$skill SKILL.md missing frontmatter"
    fi
    assert_contains "$f" "^name:" "$skill SKILL.md has name field"
done

# ── Linux installer dry-run ───────────────────────────────────────────────────
echo ""
echo "  [6] Linux installer dry-run"
TMPDIR=$(mktemp -d)
# Feed answers: skills dir, commands dir, no brain dir, confirm y
SKILLS_OUT="$TMPDIR/skills"
CMDS_OUT="$TMPDIR/commands"
printf "%s\n%s\n\ny\n" "$SKILLS_OUT" "$CMDS_OUT" | bash "$REPO_DIR/install-linux.sh" > "$TMPDIR/install.log" 2>&1 || true

for skill in brain-sync wiki-setup brain-plan brain-run ui-tokens; do
    assert_dir "$SKILLS_OUT/$skill" "linux installer: skill $skill installed"
done
assert_file "$CMDS_OUT/brain-plan.md" "linux installer: brain-plan.md installed"
assert_file "$CMDS_OUT/brain-run.md"  "linux installer: brain-run.md installed"
rm -rf "$TMPDIR"

# ── wiki-watch.sh: OS detection ───────────────────────────────────────────────
echo ""
echo "  [7] wiki-watch.sh"
assert_contains "$REPO_DIR/wiki-watch.sh" "Darwin"       "wiki-watch.sh handles macOS"
assert_contains "$REPO_DIR/wiki-watch.sh" "Linux"        "wiki-watch.sh handles Linux"
assert_contains "$REPO_DIR/wiki-watch.sh" "fswatch"      "wiki-watch.sh uses fswatch on macOS"
assert_contains "$REPO_DIR/wiki-watch.sh" "inotifywait"  "wiki-watch.sh uses inotifywait on Linux"
assert_contains "$REPO_DIR/wiki-watch.sh" "DEBOUNCE"     "wiki-watch.sh has debounce"

# ── README ────────────────────────────────────────────────────────────────────
echo ""
echo "  [8] README"
assert_contains "$REPO_DIR/README.md" "install-macos.sh"  "README mentions macOS installer"
assert_contains "$REPO_DIR/README.md" "install-linux.sh"  "README mentions Linux installer"
assert_contains "$REPO_DIR/README.md" "fswatch"           "README mentions fswatch"
assert_contains "$REPO_DIR/README.md" "inotify-tools"     "README mentions inotify-tools"
assert_contains "$REPO_DIR/README.md" "create-mo/brained-flow" "README has correct repo URL"

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "  ─────────────────────────────────────────"
TOTAL=$((PASS + FAIL))
echo "  Results: $PASS/$TOTAL passed"
[ "$FAIL" -eq 0 ] && echo "  All tests passed." || echo "  $FAIL test(s) failed."
echo ""
[ "$FAIL" -eq 0 ]
