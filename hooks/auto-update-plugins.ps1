# Claude Code Mastery — Auto-Update Plugin Marketplaces (PowerShell)
# Runs on SessionStart (startup matcher) — max once per hour

$ErrorActionPreference = 'Stop'

$MarketplaceBase = Join-Path $HOME '.claude\plugins\marketplaces'
$LockFile = Join-Path $env:TEMP 'claude-plugin-update.lock'
$CacheFile = Join-Path $env:TEMP 'claude-plugin-last-update'
$UpdateInterval = 3600  # Check at most once per hour (in seconds)

# Avoid concurrent executions
if (Test-Path $LockFile) {
    exit 0
}

# Check if we already updated recently
if (Test-Path $CacheFile) {
    $LastUpdate = [int](Get-Content $CacheFile -ErrorAction SilentlyContinue) 2>$null
    if (-not $LastUpdate) { $LastUpdate = 0 }
    $Now = [int][double]::Parse((Get-Date -UFormat %s))
    $Diff = $Now - $LastUpdate
    if ($Diff -lt $UpdateInterval) {
        exit 0
    }
}

# Create lock file with cleanup via try/finally
try {
    $PID | Out-File -FilePath $LockFile -Force

    # Track if any marketplace was updated
    $UpdatesFound = 0

    # Check if marketplace base directory exists
    if (-not (Test-Path $MarketplaceBase -PathType Container)) {
        [int][double]::Parse((Get-Date -UFormat %s)) | Out-File -FilePath $CacheFile -Force
        exit 0
    }

    # Iterate over all marketplace directories
    foreach ($MarketplaceDir in (Get-ChildItem $MarketplaceBase -Directory)) {
        $GitDir = Join-Path $MarketplaceDir.FullName '.git'
        if (-not (Test-Path $GitDir -PathType Container)) {
            continue
        }

        $MarketplaceName = $MarketplaceDir.Name

        Push-Location $MarketplaceDir.FullName
        if (-not $?) { continue }

        try {
            $OldSHA = git rev-parse HEAD 2>$null
            if (-not $OldSHA) { $OldSHA = 'none' }

            git fetch --quiet origin 2>$null
            if ($LASTEXITCODE -ne 0) { continue }

            # Get default branch name
            $DefaultBranch = git symbolic-ref refs/remotes/origin/HEAD 2>$null
            if ($DefaultBranch) {
                $DefaultBranch = $DefaultBranch -replace '^refs/remotes/origin/', ''
            } else {
                $DefaultBranch = 'main'
            }

            git reset --quiet --hard "origin/$DefaultBranch" 2>$null
            if ($LASTEXITCODE -ne 0) { continue }

            $NewSHA = git rev-parse HEAD 2>$null
            if (-not $NewSHA) { $NewSHA = 'none' }

            if ($OldSHA -ne $NewSHA) {
                Write-Output "Marketplace '$MarketplaceName' updated. Run '/plugin update' to apply changes."
                $UpdatesFound++
            }
        } finally {
            Pop-Location
        }
    }

    # Record timestamp of last check
    [int][double]::Parse((Get-Date -UFormat %s)) | Out-File -FilePath $CacheFile -Force

    if ($UpdatesFound -gt 0) {
        Write-Output "$UpdatesFound marketplace(s) updated. Consider running '/plugin update' to apply."
    }

    exit 0
} finally {
    Remove-Item $LockFile -Force -ErrorAction SilentlyContinue
}
