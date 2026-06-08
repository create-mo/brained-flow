# install.ps1 — interactive installer for brained-flow
# Asks the user for target paths before copying anything.

$ErrorActionPreference = "Stop"
$scriptDir = $PSScriptRoot

Write-Host ""
Write-Host "  brained-flow installer" -ForegroundColor Cyan
Write-Host "  ─────────────────────────────────────────" -ForegroundColor DarkGray
Write-Host ""

# ── 1. Cowork skills directory ────────────────────────────────────────────────

$defaultSkills = "$env:APPDATA\Claude\skills"
Write-Host "  [1/3] Cowork skills directory" -ForegroundColor Yellow
Write-Host "        Where Cowork loads skills from." -ForegroundColor DarkGray
Write-Host "        Default: $defaultSkills"
$inputSkills = Read-Host "        Press Enter to use default, or type a path"
$skillsDest = if ($inputSkills.Trim() -eq "") { $defaultSkills } else { $inputSkills.Trim() }

# ── 2. Claude Code commands directory ────────────────────────────────────────

$defaultCommands = Join-Path (Get-Location) ".claude\commands"
Write-Host ""
Write-Host "  [2/3] Claude Code commands directory" -ForegroundColor Yellow
Write-Host "        Where /brain-plan and /brain-run slash commands go." -ForegroundColor DarkGray
Write-Host "        Default: $defaultCommands  (current folder)"
$inputCommands = Read-Host "        Press Enter to use default, or type a path"
$commandsDest = if ($inputCommands.Trim() -eq "") { $defaultCommands } else { $inputCommands.Trim() }

# ── 3. brain/ wiki directory ──────────────────────────────────────────────────

Write-Host ""
Write-Host "  [3/3] brain/ wiki directory" -ForegroundColor Yellow
Write-Host "        Where your local Markdown wiki lives (synced to claude.ai)." -ForegroundColor DarkGray
Write-Host "        Example: C:\Users\YourName\Cloud\brain"
$inputBrain = Read-Host "        Path (leave blank to skip wiki-sync setup)"
$brainDir = $inputBrain.Trim()

# ── Summary ───────────────────────────────────────────────────────────────────

Write-Host ""
Write-Host "  ─────────────────────────────────────────" -ForegroundColor DarkGray
Write-Host "  Installing to:" -ForegroundColor White
Write-Host "    Skills   → $skillsDest"
Write-Host "    Commands → $commandsDest"
if ($brainDir -ne "") {
    Write-Host "    brain/   → $brainDir"
}
Write-Host ""
$confirm = Read-Host "  Proceed? (y/n)"
if ($confirm -notmatch "^[Yy]") {
    Write-Host "  Cancelled." -ForegroundColor Red
    exit 0
}

# ── Install skills ────────────────────────────────────────────────────────────

Write-Host ""
Write-Host "  Installing Cowork skills..." -ForegroundColor Cyan

$skills = @("brain-sync", "wiki-setup", "brain-plan", "brain-run", "ui-tokens")
foreach ($skill in $skills) {
    $src = Join-Path $scriptDir "skills\$skill"
    $dst = Join-Path $skillsDest $skill
    if (Test-Path $dst) { Remove-Item $dst -Recurse -Force }
    New-Item -ItemType Directory -Path $skillsDest -Force | Out-Null
    Copy-Item $src $dst -Recurse
    Write-Host "    OK  $skill" -ForegroundColor Green
}

# ── Install commands ──────────────────────────────────────────────────────────

Write-Host ""
Write-Host "  Installing slash commands..." -ForegroundColor Cyan

New-Item -ItemType Directory -Path $commandsDest -Force | Out-Null
$commands = @("brain-plan.md", "brain-run.md")
foreach ($cmd in $commands) {
    $src = Join-Path $scriptDir "commands\$cmd"
    $dst = Join-Path $commandsDest $cmd
    Copy-Item $src $dst -Force
    Write-Host "    OK  /$($cmd -replace '\.md','')" -ForegroundColor Green
}

# ── Wiki sync scripts ─────────────────────────────────────────────────────────

if ($brainDir -ne "") {
    Write-Host ""
    Write-Host "  Checking wiki sync scripts in brain/..." -ForegroundColor Cyan
    $scripts = @("wiki-push.py", "wiki-pull.py", "wiki-watch.ps1", "wiki-sync-setup.ps1")
    $missing = $scripts | Where-Object { -not (Test-Path (Join-Path $brainDir $_)) }
    if ($missing.Count -gt 0) {
        Write-Host "    Missing scripts: $($missing -join ', ')" -ForegroundColor Yellow
        Write-Host "    → Ask Claude: 'Help me set up wiki sync' (uses wiki-setup skill)" -ForegroundColor DarkGray
    } else {
        Write-Host "    All sync scripts present." -ForegroundColor Green
    }

    $keyFile = "$env:USERPROFILE\.claude\claude-ai-session.key"
    if (-not (Test-Path $keyFile)) {
        Write-Host ""
        Write-Host "  Session key not found at $keyFile" -ForegroundColor Yellow
        Write-Host "  → Get it from claude.ai: F12 > Application > Cookies > sessionKey" -ForegroundColor DarkGray
        Write-Host "  → Save: `"YOUR_KEY`" | Out-File `"$keyFile`" -Encoding ascii -NoNewline" -ForegroundColor DarkGray
    }
}

# ── Naming warning ───────────────────────────────────────────────────────────

Write-Host ""
Write-Host "  ─────────────────────────────────────────" -ForegroundColor DarkGray
Write-Host "  IMPORTANT: Project name must match exactly in all three places:" -ForegroundColor Yellow
Write-Host "    1. claude.ai        -> Project name in the sidebar" -ForegroundColor White
Write-Host "    2. Claude Cowork    -> Folder/project name in Cowork" -ForegroundColor White
Write-Host "    3. wiki-push.py     -> PROJECT_NAME variable in the script" -ForegroundColor White
Write-Host "  A mismatch causes silent sync failures." -ForegroundColor DarkGray

# ── Done ──────────────────────────────────────────────────────────────────────

Write-Host ""
Write-Host "  ─────────────────────────────────────────" -ForegroundColor DarkGray
Write-Host "  Done!" -ForegroundColor Green
Write-Host ""
Write-Host "  Next steps:" -ForegroundColor White
Write-Host "    1. Restart Claude Cowork to load skills"
Write-Host "    2. Ask Claude: 'Help me set up wiki sync' to configure brain/"
Write-Host "    3. Start planning: 'brain-plan: <your task>'"
Write-Host ""
