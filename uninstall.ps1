# Claude Code Mastery — Uninstaller (Windows/PowerShell)
# https://github.com/alissonlinneker/claude-code-mastery
#
# Restores original configs from backups and removes installed files.
# Does NOT remove plugin marketplaces or plugins (you may want to keep them).
#
# Usage:
#   .\uninstall.ps1          # Interactive uninstall
#   .\uninstall.ps1 -Force   # Skip confirmations

[CmdletBinding()]
param(
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

# ── Constants ────────────────────────────────────────────────────────────────

$ClaudeDir = Join-Path $HOME '.claude'
$GuardStart = '# >>> claude-code-mastery >>>'
$GuardEnd = '# <<< claude-code-mastery <<<'

# ── Helpers ──────────────────────────────────────────────────────────────────

function Write-Info    { param([string]$Message) Write-Host "[INFO] $Message" -ForegroundColor Blue }
function Write-Success { param([string]$Message) Write-Host "[OK]   $Message" -ForegroundColor Green }
function Write-Warn    { param([string]$Message) Write-Host "[WARN] $Message" -ForegroundColor Yellow }

function Restore-Backup {
    param(
        [string]$FilePath,
        [string]$Description
    )
    if (-not $Description) {
        $Description = Split-Path -Leaf $FilePath
    }

    $BackupPath = "$FilePath.bak"

    if (Test-Path $BackupPath -PathType Leaf) {
        Copy-Item -Path $BackupPath -Destination $FilePath -Force
        Remove-Item $BackupPath -Force
        Write-Success "Restored $Description from backup"
    } elseif (Test-Path $FilePath -PathType Leaf) {
        Remove-Item $FilePath -Force
        Write-Success "Removed $Description (no backup to restore)"
    } else {
        Write-Info "$Description not found (already removed)"
    }
}

# ── Banner ───────────────────────────────────────────────────────────────────

Write-Host ""
Write-Host "+-------------------------------------------------+" -ForegroundColor White
Write-Host "|  Claude Code Mastery -- Uninstaller              |" -ForegroundColor White
Write-Host "+-------------------------------------------------+" -ForegroundColor White
Write-Host ""

# ── Confirm ──────────────────────────────────────────────────────────────────

if (-not $Force) {
    Write-Host "  This will:"
    Write-Host "    * Restore original configs from .bak backups"
    Write-Host "    * Remove custom skills (architect-review, context-guardian, production-audit)"
    Write-Host "    * Remove auto-update hook"
    Write-Host "    * Remove PowerShell launcher function"
    Write-Host ""
    Write-Host "  This will NOT:"
    Write-Host "    * Remove plugin marketplaces or installed plugins"
    Write-Host "    * Remove per-project .memory-bank/ or .mcp.json"
    Write-Host "    * Remove session logs (.claude-logs/)"
    Write-Host ""
    $Reply = Read-Host "  Continue? [y/N]"
    if ($Reply -notmatch '^[Yy]$') {
        Write-Host "  Aborted."
        exit 0
    }
    Write-Host ""
}

# ── Step 1: Restore config files ────────────────────────────────────────────

Write-Info "Restoring configuration files..."

Restore-Backup -FilePath (Join-Path $ClaudeDir 'CLAUDE.md') -Description 'CLAUDE.md'
Restore-Backup -FilePath (Join-Path $ClaudeDir 'settings.json') -Description 'settings.json'
Restore-Backup -FilePath (Join-Path $ClaudeDir 'settings.local.json') -Description 'settings.local.json'

# ── Step 2: Remove custom skills ────────────────────────────────────────────

Write-Info "Removing custom skills..."

$Skills = @(
    'architect-review.md',
    'context-guardian.md',
    'production-audit.md'
)

foreach ($skill in $Skills) {
    $SkillPath = Join-Path $ClaudeDir "skills\$skill"
    if (Test-Path $SkillPath -PathType Leaf) {
        Remove-Item $SkillPath -Force
        Write-Success "Removed skill: $skill"
    }
}

# Remove skills directory if empty
$SkillsDir = Join-Path $ClaudeDir 'skills'
if ((Test-Path $SkillsDir -PathType Container) -and
    @(Get-ChildItem $SkillsDir -Force -ErrorAction SilentlyContinue).Count -eq 0) {
    Remove-Item $SkillsDir -Force
    Write-Info "Removed empty skills\ directory"
}

# ── Step 3: Remove hook ─────────────────────────────────────────────────────

Write-Info "Removing hooks..."

$HookPath = Join-Path $ClaudeDir 'hooks\auto-update-plugins.ps1'
if (Test-Path $HookPath -PathType Leaf) {
    Remove-Item $HookPath -Force
    Write-Success "Removed hook: auto-update-plugins.ps1"
}

# Remove hooks directory if empty
$HooksDir = Join-Path $ClaudeDir 'hooks'
if ((Test-Path $HooksDir -PathType Container) -and
    @(Get-ChildItem $HooksDir -Force -ErrorAction SilentlyContinue).Count -eq 0) {
    Remove-Item $HooksDir -Force
    Write-Info "Removed empty hooks\ directory"
}

# ── Step 4: Remove MEMORY.md template ───────────────────────────────────────

Write-Info "Removing auto-memory template..."

$DefaultMemory = Join-Path $ClaudeDir 'projects\-default\memory\MEMORY.md'
if (Test-Path $DefaultMemory -PathType Leaf) {
    Remove-Item $DefaultMemory -Force
    Write-Success "Removed default MEMORY.md template"
}

# ── Step 5: Remove PowerShell function from $PROFILE ────────────────────────

Write-Info "Removing PowerShell launcher function..."

$ProfilePath = $PROFILE

if ($ProfilePath -and (Test-Path $ProfilePath -PathType Leaf)) {
    $ProfileContent = Get-Content $ProfilePath -Raw -ErrorAction SilentlyContinue
    if ($ProfileContent -and $ProfileContent.Contains($GuardStart)) {
        $Pattern = '(?s)# >>> claude-code-mastery >>>.*?# <<< claude-code-mastery <<<\r?\n?'
        $ProfileContent = $ProfileContent -replace $Pattern, ''
        Set-Content -Path $ProfilePath -Value $ProfileContent.TrimEnd() -Encoding UTF8
        Write-Success "Removed PowerShell function from $ProfilePath"
    } else {
        Write-Info "No launcher function found in $ProfilePath (already removed)"
    }
} else {
    Write-Info "PowerShell profile not found (nothing to remove)"
}

# ── Step 6: Restore global ~/.mcp.json ──────────────────────────────────────

$GlobalMcpBackup = Join-Path $HOME '.mcp.json.bak'
$GlobalMcpJson = Join-Path $HOME '.mcp.json'

if (Test-Path $GlobalMcpBackup -PathType Leaf) {
    Write-Info "Restoring global ~/.mcp.json from backup..."
    Copy-Item -Path $GlobalMcpBackup -Destination $GlobalMcpJson -Force
    Remove-Item $GlobalMcpBackup -Force
    Write-Success "Restored global ~/.mcp.json"
}

# ── Summary ──────────────────────────────────────────────────────────────────

Write-Host ""
Write-Host "+-------------------------------------------------+" -ForegroundColor White
Write-Host "|  Uninstall Complete!                             |" -ForegroundColor White
Write-Host "+-------------------------------------------------+" -ForegroundColor White
Write-Host ""
Write-Host "  Removed:"
Write-Host "    + Config files (originals restored from backups)" -ForegroundColor Green
Write-Host "    + Custom skills (3)" -ForegroundColor Green
Write-Host "    + Auto-update hook" -ForegroundColor Green
Write-Host "    + PowerShell launcher function" -ForegroundColor Green
Write-Host ""
Write-Host "  Kept:"
Write-Host "    * Plugin marketplaces and installed plugins"
Write-Host "    * Per-project .memory-bank/ directories"
Write-Host "    * Per-project .mcp.json files"
Write-Host "    * Session logs (.claude-logs/)"
Write-Host ""
Write-Host "  Reload your profile to apply:  . `$PROFILE"
Write-Host ""
