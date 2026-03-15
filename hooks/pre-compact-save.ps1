# Claude Code Mastery — Pre-Compact Auto-Save (PowerShell)
# Automatically snapshots session state to Memory Bank before compaction.

$MemoryBank = ".memory-bank"
$ActiveContext = Join-Path $MemoryBank "activeContext.md"

if (-not (Test-Path $MemoryBank)) {
    Write-Output "=== PRE-COMPACT: SAVE CONTEXT NOW ==="
    Write-Output "REQUIRED BEFORE COMPACTION:"
    Write-Output "1. Save activeContext.md to Memory Bank with: current task, decisions made, modified files, next steps"
    Write-Output "2. Update progress.md with what was done in this session"
    Write-Output "3. Update techContext.md if there were technical discoveries"
    Write-Output "4. Update systemPatterns.md if there were architectural decisions"
    Write-Output "Use memory_bank_write or memory_bank_update for each file."
    Write-Output "Compaction should ONLY proceed AFTER saving context."
    Write-Output "=== END PRE-COMPACT ==="
    exit 0
}

$Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$Snapshot = @()
$Snapshot += ""
$Snapshot += "## Auto-Snapshot — $Timestamp (pre-compact)"
$Snapshot += ""

try {
    $null = git rev-parse --git-dir 2>$null
    if ($LASTEXITCODE -eq 0) {
        $Branch = git branch --show-current 2>$null
        $LastCommit = git log --oneline -1 2>$null
        $Modified = git diff --name-only 2>$null | Select-Object -First 20
        $Staged = git diff --cached --name-only 2>$null | Select-Object -First 20

        $Snapshot += "### Git State"
        $Snapshot += "- Branch: $Branch"
        $Snapshot += "- Last commit: $LastCommit"
        $Snapshot += ""

        if ($Modified) {
            $Snapshot += "### Modified Files"
            foreach ($f in $Modified) { $Snapshot += "- $f" }
            $Snapshot += ""
        }

        if ($Staged) {
            $Snapshot += "### Staged Files"
            foreach ($f in $Staged) { $Snapshot += "- $f" }
            $Snapshot += ""
        }
    }
} catch { }

$Snapshot += "### Note"
$Snapshot += "This snapshot was auto-saved by the PreCompact hook. Claude should read this after compact to restore context."
$Snapshot += ""

$SnapshotText = $Snapshot -join "`n"

if (Test-Path $ActiveContext) {
    $Existing = Get-Content $ActiveContext -Raw
    $SnapshotText + "`n" + $Existing | Set-Content $ActiveContext -Encoding UTF8
} else {
    $SnapshotText | Set-Content $ActiveContext -Encoding UTF8
}

Write-Output "=== PRE-COMPACT: CONTEXT AUTO-SAVED ==="
Write-Output "Auto-snapshot saved to activeContext.md with git state and timestamp."
Write-Output "STILL RECOMMENDED:"
Write-Output "1. Update activeContext.md with current task details and decisions"
Write-Output "2. Update progress.md with what was done in this session"
Write-Output "=== END PRE-COMPACT ==="
