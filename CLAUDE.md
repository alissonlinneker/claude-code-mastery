# Claude Code Mastery

## Project Language
All project files, comments, and documentation MUST be in English.

## Conventions
- Conventional Commits in English (`feat:`, `fix:`, `refactor:`, `docs:`, `test:`, `chore:`)
- Shell scripts must pass `bash -n` syntax check
- JSON files must be valid (parseable by `python3 -c "import json; json.load(open('file'))"`)
- Skills must have valid YAML frontmatter (`name`, `description`)
- No personal data, credentials, or API keys in any file
- Test before committing: `bash tests/test-install.sh`

## Structure
- `configs/` — Configuration templates installed to `~/.claude/`
- `skills/` — Custom skill files installed to `~/.claude/skills/`
- `hooks/` — Hook scripts installed to `~/.claude/hooks/`
- `shell/` — Shell launcher functions appended to shell config
- `docs/` — Reference documentation
- `tests/` — Validation test suites
