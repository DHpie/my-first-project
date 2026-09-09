# AIWorkSpace

> AI-driven fullstack development workspace based on **Harness + OpenSpec + Superpowers** methodology.

## Overview

This is a monorepo workspace that manages AI-driven development tooling and coordinates frontend/backend subprojects via **Git Submodules**.

- **Harness** - Agent lifecycle control and configuration layer (`.harness/`, `.agent/`, `.qoder/`)
- **OpenSpec** - Spec-Driven Development (SDD), agree on specs before writing code (`openspec/`)
- **Superpowers** - Agentic skills framework with mandatory workflows (`skills/`)

## Submodules

| Path | Repository | Tech Stack | Description |
|------|-----------|------------|-------------|
| `frontend/` | [my-first-project-frontend](https://github.com/DHpie/my-first-project-frontend) | React 18 + TypeScript + Vite 5 | User management UI |
| `backend/` | [my-first-project-backend](https://github.com/DHpie/my-first-project-backend) | Java 21 + Spring Boot 3.3 + JPA | User CRUD REST API |

Each submodule is an independent repository with its own development lifecycle. The workspace root manages overall architecture, specs, and AI agent configuration.

## Directory Structure

```
AIWorkSpace/
+-- .harness/                    # Harness configuration
|   +-- config.md                # Agent behavior constraints, quality gates, lifecycle
+-- .agent/                      # AI agent instructions
|   +-- instructions.md          # Workflow instructions, skill reference, TDD enforcement
+-- .qoder/                      # Qoder-specific integration (OpenSpec-generated)
|   +-- commands/opsx/           # Slash commands: explore, propose, apply, archive, sync, update
|   +-- skills/                  # Skill definitions: openspec-explore, openspec-propose, etc.
+-- openspec/                    # OpenSpec spec-driven development
|   +-- config.yaml              # Configuration (schema: spec-driven, ai_tools: qoder)
|   +-- specs/                   # Feature specifications (requirements + scenarios)
|   +-- changes/                 # In-flight change proposals
|       +-- archive/             # Completed and archived changes
+-- skills/                      # Superpowers skills framework (13 mandatory skills)
+-- frontend/                    # [submodule] React + Vite + TypeScript frontend
+-- backend/                     # [submodule] Spring Boot + JPA backend
+-- docs/                        # Long-lived documentation
+-- .gitmodules                  # Git submodule configuration
+-- .gitignore
+-- README.md
```

## Development Workflow

The basic workflow follows Superpowers' mandatory skill chain:

1. **brainstorming** - Refine ideas through questions, classify (spike/bounded/architectural)
2. **using-git-worktrees** - Create isolated workspace on new branch
3. **writing-plans** - Break work into 2-5 min tasks with exact file paths
4. **subagent-driven-development** - Fresh subagent per task, two-stage review
5. **test-driven-development** - RED -> GREEN -> REFACTOR (enforced throughout)
6. **requesting-code-review** - Review against plan between tasks
7. **verification-before-completion** - Fresh evidence required before claiming done
8. **finishing-a-development-branch** - Verify tests, merge/PR/keep/discard

OpenSpec runs in parallel for spec management:

1. **Explore** - Think through ideas, understand requirements
2. **Propose** - Create change with proposal + specs + design + tasks
3. **Apply** - Implement tasks following TDD workflow
4. **Archive** - Move completed changes to archive

## Core Principles

| Principle | Source | Description |
|-----------|--------|-------------|
| Test first | Superpowers | NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST |
| Systematic over ad-hoc | Superpowers | 4-phase debugging, process over guessing |
| Fluid not rigid | OpenSpec | Update any artifact anytime |
| Agree before building | OpenSpec | Specs before code |
| Complexity reduction | Both | Simplicity as primary goal |
| Evidence over claims | Both | Verify before declaring success |

## Quick Start

### Clone

```bash
# Clone with submodules
git clone --recurse-submodules git@github.com:DHpie/my-first-project.git
cd my-first-project

# If already cloned, initialize submodules:
git submodule update --init --recursive
```

### Develop

1. Read `.agent/instructions.md` for agent workflow
2. Read `skills/using-superpowers/SKILL.md` for skills overview
3. Check `openspec/specs/` for current specifications
4. Before any task: check `skills/` for relevant skills

### Update Submodules

```bash
# Pull latest for all submodules
git submodule update --remote

# Or update a specific submodule
cd frontend && git pull origin main && cd ..
git add frontend && git commit -m "chore: update frontend submodule"
```

## References

- [OpenSpec](https://github.com/Fission-AI/OpenSpec) - Spec-driven development framework
- [Superpowers](https://github.com/obra/superpowers) - Agentic skills framework (MIT License)

## License

MIT
