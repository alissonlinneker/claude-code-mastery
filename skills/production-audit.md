---
name: production-audit
description: Use when the user wants to audit a codebase for production readiness, security, performance, or code quality. For security-specific scans, prefer /shield:shield (full tooling) or /shield:security-auditor (intelligence layer). This skill covers the broader production readiness checklist beyond security.
---

# Production Code Audit

Audit a codebase for production readiness across security, performance, architecture, and quality. For security-specific analysis, use Shield (`/shield:shield` for automated tools, `/shield:security-auditor` for manual intelligence).

## When to Use

- "audit the codebase", "review code", "prepare for production"
- Before production deploy
- Before making a repository public
- Periodic quality review

## Integration with Shield

Shield handles security comprehensively (SAST, SCA, secrets, pentest, compliance). Use this skill for the **non-security** production checklist:

| Concern | Tool |
|---------|------|
| Security vulnerabilities | `/shield:shield` (automated) |
| Security intelligence | `/shield:security-auditor` (manual analysis) |
| Performance, architecture, quality, testing | This skill (`production-audit`) |

## Process

### 1. Autonomous Discovery

Without asking the user:
1. Scan all project files recursively
2. Identify tech stack (package.json, requirements.txt, composer.json)
3. Map architecture, structure, dependencies
4. Identify entry points (main, routes, controllers)
5. Read Memory Bank for project context

### 2. Scan by Category

**Performance:**
- [ ] N+1 queries
- [ ] Missing database indexes
- [ ] Sync operations that should be async
- [ ] Missing caching
- [ ] Inefficient algorithms (O(n²)+)
- [ ] Large bundle size
- [ ] Memory leaks

**Architecture:**
- [ ] Circular dependencies
- [ ] Tight coupling
- [ ] God classes (>500 lines or >20 methods)
- [ ] Separation of concerns violated
- [ ] Poor module boundaries

**Code Quality:**
- [ ] High cyclomatic complexity (>10)
- [ ] Code duplication
- [ ] Magic numbers
- [ ] Inconsistent naming
- [ ] Missing error handling
- [ ] Dead code
- [ ] TODO/FIXME pending

**Testing:**
- [ ] Critical paths untested
- [ ] Coverage < 80%
- [ ] Edge cases not tested
- [ ] No integration tests

**Production Readiness:**
- [ ] Environment variables missing
- [ ] Logging/monitoring absent
- [ ] Error tracking absent
- [ ] Health checks absent
- [ ] Documentation incomplete

### 3. Report (do NOT auto-fix)

Present structured report with severity levels (CRITICAL/HIGH/MEDIUM/LOW). Only apply fixes AFTER explicit user approval.

### 4. Save to Memory Bank

After audit:
- Update `techContext.md` with technical findings
- Update `progress.md` with audit status
- Create GitHub issues for critical/high findings
