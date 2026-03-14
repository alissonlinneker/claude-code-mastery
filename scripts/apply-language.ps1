# Claude Code Mastery — Apply Language to Hooks (PowerShell)
# Usage: .\scripts\apply-language.ps1 [-Lang pt-BR]

param(
    [string]$Lang = "en"
)

$RepoDir = Split-Path -Parent $PSScriptRoot
$LangFile = Join-Path $RepoDir "configs/i18n/$Lang.json"
$Settings = Join-Path $HOME ".claude/settings.json"

if (-not (Test-Path $LangFile)) {
    Write-Host "Error: Language file not found: $LangFile" -ForegroundColor Red
    Write-Host "Available languages:"
    Get-ChildItem (Join-Path $RepoDir "configs/i18n") -Filter "*.json" | ForEach-Object { $_.BaseName }
    exit 1
}

if (-not (Test-Path $Settings)) {
    Write-Host "Error: Settings file not found. Run install.ps1 first." -ForegroundColor Red
    exit 1
}

# Backup
Copy-Item $Settings "$Settings.bak"

$strings = Get-Content $LangFile -Raw | ConvertFrom-Json
$config = Get-Content $Settings -Raw | ConvertFrom-Json

# Update simple hook messages
foreach ($hook in $config.hooks.UserPromptSubmit) {
    $hook.hooks[0].command = "Write-Output '$($strings.prompt_reminder)'"
}
foreach ($hook in $config.hooks.Stop) {
    $hook.hooks[0].command = "Write-Output '$($strings.stop_reminder)'"
}
foreach ($hook in $config.hooks.TaskCompleted) {
    $hook.hooks[0].command = "Write-Output '$($strings.task_completed_reminder)'"
}

# Update PreCompact
foreach ($hook in $config.hooks.PreCompact) {
    $cmd = @(
        "Write-Output '$($strings.pre_compact_header)'"
        "Write-Output '$($strings.pre_compact_required)'"
        "Write-Output '$($strings.pre_compact_step_1)'"
        "Write-Output '$($strings.pre_compact_step_2)'"
        "Write-Output '$($strings.pre_compact_step_3)'"
        "Write-Output '$($strings.pre_compact_step_4)'"
        "Write-Output '$($strings.pre_compact_instruction)'"
        "Write-Output '$($strings.pre_compact_warning)'"
        "Write-Output '$($strings.pre_compact_footer)'"
    ) -join "; "
    $hook.hooks[0].command = $cmd
}

$config | ConvertTo-Json -Depth 10 | Set-Content $Settings -Encoding UTF8

Write-Host "Language set to: $Lang" -ForegroundColor Green
Write-Host "Backup saved: $Settings.bak"
