# Documentation

Project documentation and long-lived reference material.

## Monorepo Architecture

This workspace uses **Git Submodules** to manage subprojects:

| Submodule | Repository | Description |
|-----------|-----------|-------------|
| `frontend/` | [my-first-project-frontend](https://github.com/DHpie/my-first-project-frontend) | React + Vite + TypeScript UI |
| `backend/` | [my-first-project-backend](https://github.com/DHpie/my-first-project-backend) | Spring Boot + JPA REST API |

Submodules are independently versioned. The workspace root coordinates architecture, specs, and AI agent tooling.

## Structure

- `adr/` - Architecture Decision Records (industry-standard pattern)

## What Goes Here

| Type | Directory | Example |
|------|-----------|---------|
| Architecture decisions | `adr/` | "Use PostgreSQL over MongoDB for relational data" |
| Long-lived guides | root | Onboarding, deployment guides |
| Contributing info | root | CONTRIBUTING.md |

## What Does NOT Go Here

Specs, plans, and change artifacts belong in `openspec/` — they have their own lifecycle (propose → apply → archive) managed by OpenSpec tooling.

- **Specs** → `openspec/specs/`
- **Change proposals** → `openspec/changes/<name>/proposal.md`
- **Design docs** → `openspec/changes/<name>/design.md`
- **Implementation plans** → `openspec/changes/<name>/tasks.md`

## ADR Convention

Each ADR lives in `docs/adr/` with the format:

```
docs/adr/
  0001-use-postgresql.md
  0002-adopt-event-sourcing.md
```

Numbered sequentially. Each ADR contains: Title, Status, Context, Decision, Consequences.
