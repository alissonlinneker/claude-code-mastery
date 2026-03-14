# Claude Code Mastery — Zero-Config Launcher (PowerShell)
# Source: https://github.com/alissonlinneker/claude-code-mastery
#
# This function wraps the `claude` CLI to auto-configure
# per-project Memory Bank, .gitignore, and session logging.
#
# Usage: claude [args...]

function claude_code {
    $ProjectDir = $PWD.Path
    $ProjectName = Split-Path -Leaf $ProjectDir
    $LogDir = Join-Path $ProjectDir '.claude-logs'
    $LogFile = Join-Path $LogDir ("session_" + (Get-Date -Format 'yyyyMMdd_HHmmss') + ".log")

    # -- Guard: prevent setup in home directory --
    if ($ProjectDir -eq $HOME) {
        Write-Host ""
        Write-Host "  ⚠  Cannot run Claude Code Mastery in home directory."
        Write-Host "     Navigate to a project directory first."
        Write-Host ""
        return 1
    }

    # -- Auto-configure Memory Bank MCP (idempotent) --
    $McpFile = Join-Path $ProjectDir '.mcp.json'
    if (-not (Test-Path $McpFile)) {
        $McpContent = @'
{
  "mcpServers": {
    "memory-bank": {
      "type": "stdio",
      "command": "npx",
      "args": [
        "-y",
        "@allpepper/memory-bank-mcp"
      ],
      "env": {
        "MEMORY_BANK_ROOT": "./.memory-bank"
      }
    }
  }
}
'@
        Set-Content -Path $McpFile -Value $McpContent -Encoding UTF8
        Write-Host "  [+] Created .mcp.json (Memory Bank MCP)"
    }

    # -- Create Memory Bank directory --
    $MemoryBankDir = Join-Path $ProjectDir '.memory-bank'
    if (-not (Test-Path $MemoryBankDir)) {
        New-Item -ItemType Directory -Path $MemoryBankDir -Force | Out-Null
        Write-Host "  [+] Created .memory-bank/"
    }

    # -- Update .gitignore (append-only) --
    $Gitignore = Join-Path $ProjectDir '.gitignore'
    $Entries = @('.memory-bank/', '.mcp.json', '.claude-logs/')

    if (Test-Path $Gitignore) {
        foreach ($entry in $Entries) {
            if (-not (Select-String -Path $Gitignore -Pattern ([regex]::Escape($entry)) -SimpleMatch -Quiet)) {
                Add-Content -Path $Gitignore -Value $entry
                Write-Host "  [+] Added '$entry' to .gitignore"
            }
        }
    } else {
        $GitignoreContent = @("# Claude Code") + $Entries
        Set-Content -Path $Gitignore -Value ($GitignoreContent -join "`n") -Encoding UTF8
        Write-Host "  [+] Created .gitignore"
    }

    # -- Create log directory --
    if (-not (Test-Path $LogDir)) {
        New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
    }

    # -- Display diagnostics --
    Write-Host ""
    Write-Host "┌──────────────────────────────────────────────┐"
    Write-Host "│  Claude Code — $ProjectName"
    Write-Host "└──────────────────────────────────────────────┘"
    Write-Host ""
    Write-Host "  --- Project Diagnostics ---"

    # CLAUDE.md status
    $ClaudeMd = Join-Path $ProjectDir 'CLAUDE.md'
    if (Test-Path $ClaudeMd) {
        $CmdSize = (Get-Item $ClaudeMd).Length
        Write-Host "  CLAUDE.md       [OK] $CmdSize bytes"
    } else {
        Write-Host "  CLAUDE.md       [--] not found"
    }

    # Memory Bank status
    if (Test-Path $MemoryBankDir) {
        $MbFiles = Get-ChildItem $MemoryBankDir -Filter '*.md' -File -ErrorAction SilentlyContinue
        $MbCount = if ($MbFiles) { @($MbFiles).Count } else { 0 }
        if ($MbCount -gt 0) {
            Write-Host "  Memory Bank     [OK] $MbCount files"
            $MbFiles | Sort-Object Name | ForEach-Object {
                $FSize = $_.Length
                Write-Host "    - $($_.Name) (${FSize}B)"
            }
        } else {
            Write-Host "  Memory Bank     [OK] empty (new project)"
        }
    }

    # MCP status
    if (Test-Path $McpFile) {
        Write-Host "  MCP             [OK] configured"
    }

    # Git status
    $GitDir = & git -C $ProjectDir rev-parse --git-dir 2>$null
    if ($LASTEXITCODE -eq 0) {
        $Branch = & git -C $ProjectDir branch --show-current 2>$null
        if (-not $Branch) { $Branch = "detached" }
        $Modified = @(& git -C $ProjectDir status --short 2>$null).Count
        $LastCommit = & git -C $ProjectDir log --oneline -1 2>$null
        if (-not $LastCommit) { $LastCommit = "no commits" }
        Write-Host "  Branch          $Branch"
        Write-Host "  Modified        $Modified files"
        Write-Host "  Last commit     $LastCommit"
    }

    Write-Host ""
    Write-Host "  Log: $LogFile"
    Write-Host ""

    # -- Launch Claude Code --
    & claude @args 2>&1 | Tee-Object -Append -FilePath $LogFile
    return $LASTEXITCODE
}

# Alias
Set-Alias -Name claude -Value claude_code
