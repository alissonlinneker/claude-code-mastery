---
name: architect-review
description: Use when reviewing system architecture, evaluating design decisions, or assessing scalability/maintainability of a project. Invoke BEFORE approving or implementing major architectural changes.
---

# Architecture Review

## When to Use

- Reviewing system architecture or major design changes
- Evaluating scalability, resilience, or maintainability
- Assessing compliance with architecture patterns
- Before implementing new services, APIs, or data models
- When refactoring significant portions of a codebase

## Do NOT Use When

- Small code changes without architectural impact
- Single-file bug fixes
- UI-only changes without backend implications

## Review Process

### 1. Gather Context

- Read Memory Bank (`systemPatterns.md`, `techContext.md`, `projectbrief.md`)
- Read CLAUDE.md of the project (if exists)
- Identify current architecture patterns in use
- Map dependencies and data flow

### 2. Evaluate Architecture

**Checklist:**

- [ ] **Separation of Concerns** — Each module/service has a single, clear responsibility
- [ ] **Dependency Direction** — Dependencies point inward (Clean Architecture)
- [ ] **API Boundaries** — Clear contracts between services/modules
- [ ] **Data Flow** — No circular dependencies, clear ownership
- [ ] **Error Handling** — Failures are isolated, don't cascade
- [ ] **Scalability** — Bottlenecks identified, horizontal scaling possible
- [ ] **Security** — Auth/authz at boundaries, data validation, secrets management
- [ ] **Observability** — Logging, metrics, tracing in place
- [ ] **Testability** — Components can be tested in isolation

### 3. Identify Risks

For each risk found:
- **What:** Description of the risk
- **Impact:** What happens if it materializes (High/Medium/Low)
- **Likelihood:** How likely is it (High/Medium/Low)
- **Mitigation:** What to do about it

### 4. Recommend Improvements

- Present 2-3 options with trade-offs
- Lead with recommended option and reasoning
- Consider migration path from current state
- Estimate complexity (not time)

### 5. Document

- Update `systemPatterns.md` in Memory Bank with decisions
- Update `techContext.md` if tech stack changes
- Create GitHub issue for tracking if actionable

## Architecture Patterns Reference

### For Node.js/TypeScript Projects
- Clean Architecture with dependency injection
- Repository pattern for data access
- Event-driven for async operations
- API-first design (REST or GraphQL)

### For Python Projects
- FastAPI with dependency injection
- Repository + Service layer pattern
- Async handlers for I/O-bound operations
- Pydantic models for validation

### For PHP Projects
- MVC or Service-oriented architecture
- Dependency injection container
- Repository pattern for data access
- Middleware pipeline for cross-cutting concerns

### For Monorepos
- Turborepo/Nx workspace organization
- Shared packages with clear boundaries
- Independent deployability per app
- Consistent tooling across packages

## Output Format

```
## Architecture Review: [Component/System]

### Current State
[Brief description of current architecture]

### Findings
1. [Finding 1 — severity: high/medium/low]
2. [Finding 2 — severity: high/medium/low]

### Recommendations
1. [Recommendation with trade-offs]
2. [Alternative approach]

### Risks
| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|

### Decision
[Chosen approach and rationale]
```
