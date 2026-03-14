# Troubleshooting Guide

Common issues and solutions for Claude Code Mastery.

---

## Installation Issues

### `claude: command not found` after install

The Claude Code CLI is not in your PATH, or your shell has not reloaded the configuration.

**Solution:**

```bash
# Reload your shell configuration
source ~/.zshrc    # macOS / zsh
source ~/.bashrc   # Linux / bash

# Or open a new terminal window
```

If the command is still not found, verify Claude Code CLI is installed:

```bash
npm list -g @anthropic-ai/claude-code
```

### Installer fails on prerequisites

The installer checks for required tools before proceeding. If it fails, install the missing prerequisites.

**Solution:**

```bash
# Install Node.js (required for Memory Bank MCP)
# macOS
brew install node

# Ubuntu/Debian
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt-get install -y nodejs

# Install Git
# macOS
brew install git

# Ubuntu/Debian
sudo apt-get install -y git

# Install Claude Code CLI
npm install -g @anthropic-ai/claude-code
```

### Permission denied on install.sh

The installer script does not have execute permission.

**Solution:**

```bash
chmod +x install.sh
./install.sh
```

### Shell function already exists

If you see a warning that the shell function already exists, this is safe to ignore. The installer is idempotent — it uses guard markers to detect existing installations and will update in place without duplicating content.

---

## Memory Bank Issues

### Memory Bank not reading at session start

The Memory Bank MCP server may not be configured or enabled.

**Check `.mcp.json` exists in the project root:**

```bash
cat .mcp.json
```

It should contain the Memory Bank MCP configuration:

```json
{
  "mcpServers": {
    "memory-bank": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@allpepper/memory-bank-mcp"],
      "env": {
        "MEMORY_BANK_ROOT": "./.memory-bank"
      }
    }
  }
}
```

**Check `settings.local.json` has MCP auto-enable:**

```bash
cat ~/.claude/settings.local.json
```

It must include:

```json
{
  "enableAllProjectMcpServers": true
}
```

If this setting is missing, MCP servers defined in `.mcp.json` will not start automatically.

### Memory Bank files not created

The `.memory-bank/` directory must exist in the project root for the MCP server to write files.

**Solution:**

```bash
mkdir -p .memory-bank
```

The Memory Bank MCP server creates files inside this directory. If the directory does not exist, reads and writes will fail silently.

### MCP server not starting

The Memory Bank MCP runs via `npx`, which requires Node.js.

**Check Node.js and npx are available:**

```bash
node --version
npx --version
```

**Check the package is accessible:**

```bash
npx -y @allpepper/memory-bank-mcp --help
```

If you are behind a corporate proxy or firewall, `npx` may fail to download the package. In that case, install it globally:

```bash
npm install -g @allpepper/memory-bank-mcp
```

Then update `.mcp.json` to use the global binary path instead of `npx`.

### Context lost after compact

Context loss after `/compact` means the PreCompact hook is not saving state to the Memory Bank, or the SessionStart hook is not restoring it.

**Verify the PreCompact hook is configured in `settings.json`:**

```json
{
  "hooks": {
    "PreCompact": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "echo 'Save all context to Memory Bank before compact'"
          }
        ]
      }
    ]
  }
}
```

**Verify the SessionStart hook fires and reads Memory Bank:**

Check the CLAUDE.md instructions include the mandatory Memory Bank read at session start. The `SessionStart` hook in `settings.json` should trigger the context restoration flow.

**Manual recovery:** If context was lost, you can still read the Memory Bank manually by asking Claude to read all `.md` files in `.memory-bank/`.

---

## Hook Issues

### Hooks not firing

Hooks are defined in `~/.claude/settings.json`. If they are not firing, the configuration may be invalid.

**Check settings.json is valid JSON:**

```bash
cat ~/.claude/settings.json | python3 -m json.tool
```

If this command outputs an error, the JSON is malformed. Common issues:
- Trailing commas after the last item in arrays or objects
- Missing quotes around keys or values
- Unescaped special characters in strings

**Check hook events are correctly named:**

Valid hook events are:
- `SessionStart`
- `UserPromptSubmit`
- `PreCompact`
- `Stop`
- `TaskCompleted`
- `PreToolUse`

Event names are case-sensitive. `sessionstart` or `session_start` will not work.

### PreToolUse not blocking commands

The `PreToolUse` hook uses matchers and `jq` to inspect tool calls. If it is not blocking as expected, there are two common causes.

**Check `jq` is installed:**

```bash
jq --version
```

If not installed:

```bash
# macOS
brew install jq

# Ubuntu/Debian
sudo apt-get install -y jq
```

**Check regex patterns in the hook matcher:**

The matcher string must match the tool name exactly. For example, to match all Bash tool calls:

```json
{
  "matcher": "Bash",
  "hooks": [
    {
      "type": "command",
      "command": "your-blocking-script.sh"
    }
  ]
}
```

An empty matcher (`""`) matches all tool calls. Verify that the matcher targets the correct tool.

### Auto-update not running

The auto-update hook runs `hooks/auto-update-plugins.sh` at session start.

**Check the script is executable:**

```bash
ls -la ~/.claude/hooks/auto-update-plugins.sh
chmod +x ~/.claude/hooks/auto-update-plugins.sh
```

**Check for stale lock file:**

The auto-update script uses a lock file to prevent running more than once per hour. If the lock file is stale (e.g., from a crash), updates will be skipped.

```bash
# Check the lock file
ls -la /tmp/claude-plugin-update.lock 2>/dev/null

# Remove stale lock file
rm -f /tmp/claude-plugin-update.lock
```

### Hook timeout

If a hook takes too long, it will be killed. The default timeout may be too short for network-dependent operations.

**Increase the timeout in `settings.json`:**

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "your-slow-script.sh",
            "timeout": 30
          }
        ]
      }
    ]
  }
}
```

The timeout value is in seconds. For network operations (like plugin updates), 30 seconds is a reasonable value.

---

## Plugin Issues

### Plugin not found

If a plugin is not available after installation, it may not have been added to the marketplace.

**Solution — add the plugin manually:**

```bash
claude plugin marketplace add owner/repo
```

**Verify the marketplace is registered:**

Check `~/.claude/settings.json` for the `extraKnownMarketplaces` object:

```json
{
  "extraKnownMarketplaces": {
    "trailofbits": {
      "source": { "source": "github", "repo": "trailofbits/skills" }
    },
    "context-engineering-kit": {
      "source": { "source": "github", "repo": "NeoLabHQ/context-engineering-kit" }
    }
  }
}
```

### Plugin not activating

Plugins must be explicitly enabled in `settings.json`.

**Check `enabledPlugins`:**

```json
{
  "enabledPlugins": {
    "superpowers@superpowers-marketplace": true,
    "shield@shield-security": true,
    "differential-review@trailofbits": true
  }
}
```

Each plugin uses the format `plugin-name@marketplace-name` with a `true` value.

### Marketplace update fails

Plugin marketplace updates require network access and Git.

**Check network connectivity:**

```bash
curl -s https://api.github.com/rate_limit | python3 -m json.tool
```

**Try manual update:**

```bash
# Find the marketplace directory
ls ~/.claude/plugins/marketplaces/

# Pull updates manually
cd ~/.claude/plugins/marketplaces/obra/superpowers-marketplace
git pull origin main
```

If the repository has changed its default branch, update the remote:

```bash
git remote set-head origin --auto
git pull
```

---

## Shell Launcher Issues

### Diagnostics not showing

The `claude_code()` shell function displays diagnostics (project name, memory status, MCP config) when launching Claude Code. If these are not appearing, the function may not be sourced.

**Verify the function is loaded:**

```bash
# zsh
type claude_code

# bash
type -t claude_code
```

If the output is "not found", the function is not sourced. Check your shell configuration:

```bash
# Look for the claude_code function in your shell config
grep -n "claude_code" ~/.zshrc    # macOS
grep -n "claude_code" ~/.bashrc   # Linux
```

If the function is missing, re-run the installer:

```bash
./install.sh
source ~/.zshrc  # or ~/.bashrc
```

### Running in home directory

The launcher intentionally blocks running from the home directory (`~`). This prevents accidentally creating Memory Bank files and project configurations in your home directory, which would pollute it with per-project artifacts.

**Solution:** Navigate to a project directory first:

```bash
cd ~/projects/my-project
claude_code
```

### Session logs not created

Session logs are written to `.claude-logs/` in the project directory.

**Check directory permissions:**

```bash
ls -la .claude-logs/
```

If the directory does not exist, create it:

```bash
mkdir -p .claude-logs
```

If the directory exists but logs are not being written, check that the shell function has write permission:

```bash
touch .claude-logs/test.log && rm .claude-logs/test.log
```

---

## General

### Resetting to defaults

To completely reset Claude Code Mastery and start fresh:

```bash
# Run the uninstaller (restores backups if available)
./uninstall.sh

# Re-install from scratch
./install.sh
source ~/.zshrc  # or ~/.bashrc
```

The uninstaller will restore any backup files created during the original installation (e.g., `settings.json.backup`).

### Updating to a new version

To update Claude Code Mastery to the latest version:

```bash
cd /path/to/claude-code-mastery
git pull origin main
./install.sh
source ~/.zshrc  # or ~/.bashrc
```

The installer is idempotent — it will update existing configurations without duplicating them.

### Partial installation

If the installer was interrupted or partially completed, simply re-run it:

```bash
./install.sh
```

The installer is designed to be idempotent. It detects what is already installed and only adds or updates what is missing. Running it multiple times is safe and will not create duplicate entries in your shell configuration or settings files.

---

## Still stuck?

If none of the above solutions resolve your issue:

1. Check the [GitHub Issues](https://github.com/alissonlinneker/claude-code-mastery/issues) for known problems
2. Open a new issue with:
   - Your OS and shell version (`uname -a`, `echo $SHELL`, `$SHELL --version`)
   - Node.js version (`node --version`)
   - Claude Code CLI version (`claude --version`)
   - The exact error message or unexpected behavior
   - Steps to reproduce

---

## See Also

- [Configuration Reference](configuration.md) — detailed settings documentation
- [Hooks Reference](hooks.md) — hook system deep dive
- [Skills Reference](skills.md) — all available skills
- [Memory Bank Guide](memory-bank.md) — memory architecture details
- [Customization Guide](customization.md) — how to personalize your setup
