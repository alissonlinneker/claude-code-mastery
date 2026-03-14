# Claude Code Mastery — Installation Test Suite (PowerShell)
# Validates that all template files exist, are valid, and contain no personal data.
#
# Usage: pwsh tests/test-install.ps1

$ErrorActionPreference = 'Continue'

# ── Test Framework ─────────────────────────────────────────────────────────────

$Script:Pass = 0
$Script:Fail = 0
$Script:Total = 0
$Script:Errors = @()
$Script:RepoDir = Split-Path -Parent $PSScriptRoot
if (-not $Script:RepoDir -or -not (Test-Path (Join-Path $Script:RepoDir "README.md"))) {
    $Script:RepoDir = (Get-Location).Path
}

function Assert {
    param([string]$Desc, [bool]$Result)
    $Script:Total++
    if ($Result) {
        Write-Host "  ✓ $Desc" -ForegroundColor Green
        $Script:Pass++
    } else {
        Write-Host "  ✗ $Desc" -ForegroundColor Red
        $Script:Fail++
        $Script:Errors += $Desc
    }
}

function FileExists([string]$Path) {
    Test-Path (Join-Path $Script:RepoDir $Path)
}

function FileNotEmpty([string]$Path) {
    $full = Join-Path $Script:RepoDir $Path
    (Test-Path $full) -and ((Get-Item $full).Length -gt 0)
}

# ── Tests ──────────────────────────────────────────────────────────────────────

Write-Host ""
Write-Host "╔══════════════════════════════════════════════════╗"
Write-Host "║  Claude Code Mastery — Installation Tests (PS)  ║"
Write-Host "╚══════════════════════════════════════════════════╝"
Write-Host ""

# ── Config Templates ──────────────────────────────────────────────────────────

Write-Host "  Config Templates:"

Assert "configs/CLAUDE.md exists" (FileExists "configs/CLAUDE.md")
Assert "configs/CLAUDE.md is not empty" (FileNotEmpty "configs/CLAUDE.md")
Assert "configs/settings.json exists" (FileExists "configs/settings.json")
Assert "configs/settings.windows.json exists" (FileExists "configs/settings.windows.json")
Assert "configs/settings.local.json exists" (FileExists "configs/settings.local.json")
Assert "configs/MEMORY.md exists" (FileExists "configs/MEMORY.md")

Write-Host ""

# ── JSON Validation ───────────────────────────────────────────────────────────

Write-Host "  JSON Validation:"

foreach ($jsonFile in @("configs/settings.json", "configs/settings.windows.json", "configs/settings.local.json")) {
    $full = Join-Path $Script:RepoDir $jsonFile
    $valid = $false
    if (Test-Path $full) {
        try {
            Get-Content $full -Raw | ConvertFrom-Json | Out-Null
            $valid = $true
        } catch { }
    }
    Assert "$jsonFile is valid JSON" $valid
}

Write-Host ""

# ── Skills ────────────────────────────────────────────────────────────────────

Write-Host "  Custom Skills:"

foreach ($skill in @("skills/architect-review.md", "skills/context-guardian.md", "skills/production-audit.md")) {
    Assert "$skill exists" (FileExists $skill)
    Assert "$skill is not empty" (FileNotEmpty $skill)

    $full = Join-Path $Script:RepoDir $skill
    if (Test-Path $full) {
        $content = Get-Content $full -TotalCount 4
        Assert "$skill has YAML frontmatter" ($content[0] -eq "---")
        $allContent = Get-Content $full -Raw
        Assert "$skill has 'name' field" ($allContent -match "(?m)^name:")
        Assert "$skill has 'description' field" ($allContent -match "(?m)^description:")
    }
}

Write-Host ""

# ── Hooks ─────────────────────────────────────────────────────────────────────

Write-Host "  Hooks:"

Assert "hooks/auto-update-plugins.sh exists" (FileExists "hooks/auto-update-plugins.sh")
Assert "hooks/auto-update-plugins.ps1 exists" (FileExists "hooks/auto-update-plugins.ps1")

Write-Host ""

# ── Shell Functions ───────────────────────────────────────────────────────────

Write-Host "  Shell/PowerShell Functions:"

Assert "shell/claude_code.zsh exists" (FileExists "shell/claude_code.zsh")
Assert "shell/claude_code.bash exists" (FileExists "shell/claude_code.bash")
Assert "shell/claude_code.ps1 exists" (FileExists "shell/claude_code.ps1")

$ps1Full = Join-Path $Script:RepoDir "shell/claude_code.ps1"
if (Test-Path $ps1Full) {
    $ps1Content = Get-Content $ps1Full -Raw
    Assert "claude_code.ps1 defines claude_code function" ($ps1Content -match "function claude_code")
    Assert "claude_code.ps1 defines claude alias" ($ps1Content -match "Set-Alias")
}

Write-Host ""

# ── Installers ────────────────────────────────────────────────────────────────

Write-Host "  Installers:"

Assert "install.sh exists" (FileExists "install.sh")
Assert "install.ps1 exists" (FileExists "install.ps1")
Assert "uninstall.sh exists" (FileExists "uninstall.sh")
Assert "uninstall.ps1 exists" (FileExists "uninstall.ps1")

Write-Host ""

# ── Documentation ─────────────────────────────────────────────────────────────

Write-Host "  Documentation:"

Assert "README.md exists" (FileExists "README.md")
Assert "README.md is not empty" (FileNotEmpty "README.md")
Assert "LICENSE exists" (FileExists "LICENSE")

foreach ($doc in @("docs/configuration.md", "docs/hooks.md", "docs/skills.md", "docs/memory-bank.md", "docs/troubleshooting.md", "docs/customization.md")) {
    Assert "$doc exists" (FileExists $doc)
}

Write-Host ""

# ── Personal Data Check ──────────────────────────────────────────────────────

Write-Host "  Personal Data Check:"

$personalDataFound = $false
$files = Get-ChildItem $Script:RepoDir -Recurse -Include "*.md","*.json","*.sh","*.bash","*.zsh","*.ps1" |
    Where-Object { $_.FullName -notmatch '\.git[/\\]|\.memory-bank|docs[/\\]plans' }

foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
    if ($content -match '\/Users\/[a-z]|\/home\/[a-z]|@gmail\.com|@hotmail\.com|sk-[a-zA-Z0-9]{20,}|ghp_[a-zA-Z0-9]{20,}') {
        if ($content -notmatch 'github\.com/|example\.com|your-|grep.*Users|iE.*Users') {
            $personalDataFound = $true
        }
    }
}

Assert "No personal data in templates" (-not $personalDataFound)

Write-Host ""

# ── Summary ───────────────────────────────────────────────────────────────────

Write-Host "══════════════════════════════════════════════════"
Write-Host ""

if ($Script:Fail -eq 0) {
    Write-Host "  All $($Script:Total) tests passed." -ForegroundColor Green
} else {
    Write-Host "  $($Script:Fail)/$($Script:Total) tests failed:" -ForegroundColor Red
    foreach ($err in $Script:Errors) {
        Write-Host "    ✗ $err" -ForegroundColor Red
    }
}

Write-Host ""

exit $Script:Fail
