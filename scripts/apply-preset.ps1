# Claude Code Mastery — Apply Project Preset (PowerShell)
# Usage: .\scripts\apply-preset.ps1 [-Preset node]

param(
    [string]$Preset = "general"
)

$RepoDir = Split-Path -Parent $PSScriptRoot
$PresetFile = Join-Path $RepoDir "configs/presets/$Preset.json"
$Settings = Join-Path $HOME ".claude/settings.json"

if (-not (Test-Path $PresetFile)) {
    Write-Host "Error: Preset not found: $PresetFile" -ForegroundColor Red
    Write-Host "Available presets:"
    Get-ChildItem (Join-Path $RepoDir "configs/presets") -Filter "*.json" | ForEach-Object { $_.BaseName }
    exit 1
}

if (-not (Test-Path $Settings)) {
    Write-Host "Error: Settings file not found. Run install.ps1 first." -ForegroundColor Red
    exit 1
}

# Backup
Copy-Item $Settings "$Settings.bak"

$presetData = Get-Content $PresetFile -Raw | ConvertFrom-Json
$config = Get-Content $Settings -Raw | ConvertFrom-Json

# Merge permissions
$extraAllow = $presetData.permissions.allow
$currentAllow = [System.Collections.ArrayList]@($config.permissions.allow)
$added = 0

foreach ($perm in $extraAllow) {
    if ($currentAllow -notcontains $perm) {
        $currentAllow.Add($perm) | Out-Null
        $added++
    }
}

$config.permissions.allow = $currentAllow.ToArray()
$config | ConvertTo-Json -Depth 10 | Set-Content $Settings -Encoding UTF8

Write-Host "Preset applied: $($presetData.name)" -ForegroundColor Green
Write-Host "Description: $($presetData.description)"
Write-Host "Extra permissions added: $added"
Write-Host "Backup saved: $Settings.bak"
