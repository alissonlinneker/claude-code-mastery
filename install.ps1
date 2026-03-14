# Claude Code Mastery — Installer (Windows/PowerShell)
# https://github.com/alissonlinneker/claude-code-mastery
#
# Usage:
#   .\install.ps1            # Interactive install
#   .\install.ps1 -Force     # Skip confirmations
#   .\install.ps1 -DryRun    # Preview actions without changes
#
# Safety: backup-first, append-only, idempotent

[CmdletBinding()]
param(
    [switch]$Force,
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

# ── Constants ────────────────────────────────────────────────────────────────

$RepoDir = $PSScriptRoot
$ClaudeDir = Join-Path $HOME '.claude'
$GuardStart = '# >>> claude-code-mastery >>>'
$GuardEnd = '# <<< claude-code-mastery <<<'
$Version = '1.1.0'

# ── Helpers ──────────────────────────────────────────────────────────────────

function Write-Info    { param([string]$Message) Write-Host "[INFO] $Message" -ForegroundColor Blue }
function Write-Success { param([string]$Message) Write-Host "[OK]   $Message" -ForegroundColor Green }
function Write-Warn    { param([string]$Message) Write-Host "[WARN] $Message" -ForegroundColor Yellow }
function Write-Err     { param([string]$Message) Write-Host "[ERR]  $Message" -ForegroundColor Red }

function Test-DryRun {
    param([string]$Action)
    if ($DryRun) {
        Write-Host "[DRY]  Would: $Action" -ForegroundColor Yellow
        return $true
    }
    return $false
}

function Backup-File {
    param([string]$FilePath)
    if (Test-Path $FilePath -PathType Leaf) {
        $BackupPath = "$FilePath.bak"
        if (Test-DryRun "backup $FilePath -> $BackupPath") { return }
        Copy-Item -Path $FilePath -Destination $BackupPath -Force
        Write-Info "Backed up $(Split-Path -Leaf $FilePath) -> $(Split-Path -Leaf $BackupPath)"
    }
}

function Install-ConfigFile {
    param(
        [string]$Source,
        [string]$Destination,
        [string]$Description
    )
    if (-not $Description) {
        $Description = Split-Path -Leaf $Destination
    }

    if (-not (Test-Path $Source -PathType Leaf)) {
        Write-Err "Source file not found: $Source"
        return $false
    }

    Backup-File -FilePath $Destination

    if (Test-DryRun "install $Description -> $Destination") { return $true }

    $DestDir = Split-Path -Parent $Destination
    if (-not (Test-Path $DestDir -PathType Container)) {
        New-Item -ItemType Directory -Path $DestDir -Force | Out-Null
    }
    Copy-Item -Path $Source -Destination $Destination -Force
    Write-Success "Installed $Description"
    return $true
}

# ── Banner ───────────────────────────────────────────────────────────────────

Write-Host ""
Write-Host "+-------------------------------------------------+" -ForegroundColor White
Write-Host "|  Claude Code Mastery -- Installer v$Version          |" -ForegroundColor White
Write-Host "+-------------------------------------------------+" -ForegroundColor White
Write-Host ""

if ($DryRun) {
    Write-Warn "DRY RUN mode -- no changes will be made"
    Write-Host ""
}

# ── Step 1: Detect OS ───────────────────────────────────────────────────────

Write-Info "Detecting operating system..."

# Detect WSL — if running inside WSL, redirect to install.sh
if ($env:WSL_DISTRO_NAME -or $env:IS_WSL) {
    Write-Warn "WSL detected. Use install.sh instead:"
    Write-Host "  bash ./install.sh" -ForegroundColor Yellow
    exit 1
}

# Confirm we're on Windows/PowerShell
if ($IsLinux -or $IsMacOS) {
    Write-Err "This installer is for Windows/PowerShell."
    Write-Err "Use install.sh for macOS/Linux."
    exit 1
}

Write-Success "OS: Windows (PowerShell $($PSVersionTable.PSVersion))"

# ── Step 2: Check Prerequisites ─────────────────────────────────────────────

Write-Info "Checking prerequisites..."

$Missing = @()

if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
    $Missing += "claude (Claude Code CLI -- https://docs.anthropic.com/en/docs/claude-code)"
}

if (-not (Get-Command node -ErrorAction SilentlyContinue) -and -not (Get-Command npx -ErrorAction SilentlyContinue)) {
    $Missing += "node/npx (Node.js -- https://nodejs.org)"
}

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    $Missing += "git (https://git-scm.com)"
}

if ($Missing.Count -gt 0) {
    Write-Err "Missing prerequisites:"
    foreach ($m in $Missing) {
        Write-Host "  x $m" -ForegroundColor Red
    }
    exit 1
}

Write-Success "All prerequisites found"

# ── Step 3: Confirm ─────────────────────────────────────────────────────────

if (-not $Force -and -not $DryRun) {
    Write-Host ""
    Write-Info "This will install Claude Code Mastery to $ClaudeDir"
    Write-Info "Existing configs will be backed up as .bak files"
    Write-Host ""
    $Reply = Read-Host "  Continue? [Y/n]"
    if (-not $Reply) { $Reply = 'Y' }
    if ($Reply -notmatch '^[Yy]$') {
        Write-Host "  Aborted."
        exit 0
    }
    Write-Host ""
}

# ── Step 4: Create directory structure ───────────────────────────────────────

Write-Info "Setting up directory structure..."

if (-not (Test-DryRun "create $ClaudeDir\skills and $ClaudeDir\hooks")) {
    New-Item -ItemType Directory -Path (Join-Path $ClaudeDir 'skills') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $ClaudeDir 'hooks') -Force | Out-Null
}

Write-Success "Directory structure ready"

# ── Step 5: Install config files ────────────────────────────────────────────

Write-Info "Installing configuration files..."

Install-ConfigFile `
    -Source (Join-Path $RepoDir 'configs\CLAUDE.md') `
    -Destination (Join-Path $ClaudeDir 'CLAUDE.md') `
    -Description 'CLAUDE.md (global rules)'

# Use Windows-specific settings if available, otherwise fall back to default
$SettingsSource = Join-Path $RepoDir 'configs\settings.windows.json'
if (-not (Test-Path $SettingsSource -PathType Leaf)) {
    $SettingsSource = Join-Path $RepoDir 'configs\settings.json'
}
Install-ConfigFile `
    -Source $SettingsSource `
    -Destination (Join-Path $ClaudeDir 'settings.json') `
    -Description 'settings.json (hooks + permissions)'

Install-ConfigFile `
    -Source (Join-Path $RepoDir 'configs\settings.local.json') `
    -Destination (Join-Path $ClaudeDir 'settings.local.json') `
    -Description 'settings.local.json (MCP auto-enable)'

# ── Step 6: Install custom skills ───────────────────────────────────────────

Write-Info "Installing custom skills..."

Install-ConfigFile `
    -Source (Join-Path $RepoDir 'skills\architect-review.md') `
    -Destination (Join-Path $ClaudeDir 'skills\architect-review.md') `
    -Description 'skill: architect-review'

Install-ConfigFile `
    -Source (Join-Path $RepoDir 'skills\context-guardian.md') `
    -Destination (Join-Path $ClaudeDir 'skills\context-guardian.md') `
    -Description 'skill: context-guardian'

Install-ConfigFile `
    -Source (Join-Path $RepoDir 'skills\production-audit.md') `
    -Destination (Join-Path $ClaudeDir 'skills\production-audit.md') `
    -Description 'skill: production-audit'

# ── Step 7: Install hooks ───────────────────────────────────────────────────

Write-Info "Installing hooks..."

Install-ConfigFile `
    -Source (Join-Path $RepoDir 'hooks\auto-update-plugins.ps1') `
    -Destination (Join-Path $ClaudeDir 'hooks\auto-update-plugins.ps1') `
    -Description 'hook: auto-update-plugins'

# ── Step 8: Install MEMORY.md template ──────────────────────────────────────

Write-Info "Installing auto-memory template..."

$DefaultMemoryDir = Join-Path $ClaudeDir 'projects\-default\memory'

if (-not (Test-DryRun "create $DefaultMemoryDir")) {
    New-Item -ItemType Directory -Path $DefaultMemoryDir -Force | Out-Null
}

Install-ConfigFile `
    -Source (Join-Path $RepoDir 'configs\MEMORY.md') `
    -Destination (Join-Path $DefaultMemoryDir 'MEMORY.md') `
    -Description 'MEMORY.md (auto-memory template)'

# ── Step 9: Install plugin marketplaces ─────────────────────────────────────

Write-Info "Installing plugin marketplaces..."

$Marketplaces = @(
    'obra/superpowers-marketplace',
    'trailofbits/skills',
    'NeoLabHQ/context-engineering-kit',
    'alissonlinneker/shield-claude-skill'
)

foreach ($marketplace in $Marketplaces) {
    if (Test-DryRun "claude plugin marketplace add $marketplace") { continue }

    Write-Info "Adding marketplace: $marketplace"
    try {
        & claude plugin marketplace add $marketplace 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Marketplace: $marketplace"
        } else {
            Write-Warn "Could not add marketplace: $marketplace (you can add it manually later)"
        }
    } catch {
        Write-Warn "Could not add marketplace: $marketplace (you can add it manually later)"
    }
}

# ── Step 10: Install plugins ────────────────────────────────────────────────

Write-Info "Installing plugins from marketplaces..."

$Plugins = @(
    'superpowers@superpowers-marketplace',
    'shield@shield-security',
    'differential-review@trailofbits',
    'static-analysis@trailofbits',
    'audit-context-building@trailofbits',
    'supply-chain-risk-auditor@trailofbits',
    'agentic-actions-auditor@trailofbits',
    'sdd@context-engineering-kit',
    'reflexion@context-engineering-kit',
    'code-review@context-engineering-kit',
    'kaizen@context-engineering-kit'
)

foreach ($plugin in $Plugins) {
    if (Test-DryRun "claude plugin install $plugin") { continue }

    try {
        & claude plugin install $plugin 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Plugin: $plugin"
        } else {
            Write-Warn "Could not install plugin: $plugin (you can install it manually later)"
        }
    } catch {
        Write-Warn "Could not install plugin: $plugin (you can install it manually later)"
    }
}

# ── Step 11: Add PowerShell function ────────────────────────────────────────

Write-Info "Installing PowerShell launcher function..."

$ShellFuncFile = Join-Path $RepoDir 'shell\claude_code.ps1'

if (Test-Path $ShellFuncFile -PathType Leaf) {
    # Determine the PowerShell profile path
    $ProfilePath = $PROFILE

    if (-not $ProfilePath) {
        Write-Warn "Could not determine PowerShell profile path (skipping)"
    } else {
        # Ensure the profile directory exists
        $ProfileDir = Split-Path -Parent $ProfilePath
        if ($ProfileDir -and -not (Test-Path $ProfileDir -PathType Container)) {
            if (-not (Test-DryRun "create profile directory $ProfileDir")) {
                New-Item -ItemType Directory -Path $ProfileDir -Force | Out-Null
            }
        }

        # Ensure the profile file exists
        if (-not (Test-Path $ProfilePath -PathType Leaf)) {
            if (-not (Test-DryRun "create empty profile at $ProfilePath")) {
                New-Item -ItemType File -Path $ProfilePath -Force | Out-Null
            }
        }

        # Check if already installed (idempotent)
        $ProfileContent = ''
        if (Test-Path $ProfilePath -PathType Leaf) {
            $ProfileContent = Get-Content $ProfilePath -Raw -ErrorAction SilentlyContinue
        }

        if ($ProfileContent -and $ProfileContent.Contains($GuardStart)) {
            Write-Info "PowerShell function already installed in $ProfilePath (skipping)"
        } else {
            if (-not (Test-DryRun "append PowerShell function to $ProfilePath")) {
                $FuncContent = Get-Content $ShellFuncFile -Raw
                $Block = @(
                    '',
                    $GuardStart,
                    $FuncContent.TrimEnd(),
                    $GuardEnd
                ) -join "`n"
                Add-Content -Path $ProfilePath -Value $Block -Encoding UTF8
                Write-Success "PowerShell function added to $ProfilePath"
            }
        }
    }
} else {
    Write-Warn "Could not find shell function file: $ShellFuncFile"
}

# ── Step 12: Handle global ~/.mcp.json ──────────────────────────────────────

$GlobalMcpJson = Join-Path $HOME '.mcp.json'

if (Test-Path $GlobalMcpJson -PathType Leaf) {
    Write-Warn "Found global ~/.mcp.json -- Memory Bank should be per-project only"
    Backup-File -FilePath $GlobalMcpJson

    if ($Force) {
        if (-not (Test-DryRun "remove ~/.mcp.json (backed up)")) {
            Remove-Item $GlobalMcpJson -Force
            Write-Success "Removed global ~/.mcp.json (backup saved)"
        }
    } elseif (-not $DryRun) {
        $Reply = Read-Host "  Remove global ~/.mcp.json? (backed up) [Y/n]"
        if (-not $Reply) { $Reply = 'Y' }
        if ($Reply -match '^[Yy]$') {
            Remove-Item $GlobalMcpJson -Force
            Write-Success "Removed global ~/.mcp.json (backup saved)"
        } else {
            Write-Info "Keeping global ~/.mcp.json (may conflict with per-project config)"
        }
    }
}

# ── Summary ──────────────────────────────────────────────────────────────────

$ProfileDisplay = if ($PROFILE) { $PROFILE } else { '(not set)' }

Write-Host ""
Write-Host "+-------------------------------------------------+" -ForegroundColor White
Write-Host "|  Installation Complete!                          |" -ForegroundColor White
Write-Host "+-------------------------------------------------+" -ForegroundColor White
Write-Host ""
Write-Host "  Installed:"
Write-Host "    + Global rules      -> ~/.claude/CLAUDE.md" -ForegroundColor Green
Write-Host "    + Settings + hooks  -> ~/.claude/settings.json" -ForegroundColor Green
Write-Host "    + MCP auto-enable   -> ~/.claude/settings.local.json" -ForegroundColor Green
Write-Host "    + Custom skills (3) -> ~/.claude/skills/" -ForegroundColor Green
Write-Host "    + Auto-update hook  -> ~/.claude/hooks/" -ForegroundColor Green
Write-Host "    + Memory template   -> ~/.claude/projects/" -ForegroundColor Green
Write-Host "    + PS launcher       -> $ProfileDisplay" -ForegroundColor Green
Write-Host ""
Write-Host "  Next steps:"
Write-Host "    1. Reload your profile:  . `$PROFILE"
Write-Host "    2. Navigate to a project directory"
Write-Host "    3. Run: claude"
Write-Host ""
Write-Host "  The launcher will auto-configure Memory Bank, .gitignore,"
Write-Host "  and session logging for each project on first run."
Write-Host ""
Write-Host "  To uninstall: .\uninstall.ps1"
Write-Host ""
