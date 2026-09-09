# My First Project

> Based on **Harness + OpenSpec + Superpowers** methodology for AI-driven development.

## Overview

This project integrates three AI-driven development frameworks:

- **Harness** - Agent lifecycle control and configuration layer (`.harness/`, `.agent/`, `.qoder/`)
- **OpenSpec** - Spec-Driven Development (SDD), agree on specs before writing code (`openspec/`)
- **Superpowers** - Agentic skills framework with mandatory workflows (`skills/`)

## Directory Structure

```
my-first-project/
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
|   +-- brainstorming/           # Socratic design refinement (3 paths: spike/bounded/architectural)
|   |   +-- spec-document-reviewer-prompt.md
|   +-- dispatching-parallel-agents/ # Concurrent subagent workflows
|   +-- executing-plans/         # Batch execution with checkpoints
|   +-- finishing-a-development-branch/ # Merge/PR decision workflow
|   +-- receiving-code-review/   # Responding to feedback (no performative agreement)
|   +-- requesting-code-review/  # Pre-review checklist and reviewer prompt
|   |   +-- code-reviewer.md
|   +-- subagent-driven-development/ # Fresh subagent per task + two-stage review
|   |   +-- implementer-prompt.md
|   |   +-- task-reviewer-prompt.md
|   |   +-- re-review-prompt.md
|   +-- systematic-debugging/    # 4-phase root cause process
|   |   +-- root-cause-tracing.md
|   |   +-- defense-in-depth.md
|   |   +-- condition-based-waiting.md
|   +-- test-driven-development/ # RED-GREEN-REFACTOR cycle
|   |   +-- writing-good-tests.md
|   +-- using-git-worktrees/     # Parallel development branches
|   +-- using-superpowers/       # Skills system introduction
|   +-- verification-before-completion/ # Fresh evidence required before completion
|   +-- writing-plans/           # Detailed implementation plans (2-5 min tasks)
|   |   +-- plan-document-reviewer-prompt.md
|   +-- writing-skills/          # Create new skills (TDD applied to documentation)
+-- docs/                        # Long-lived documentation
|   +-- adr/                     # Architecture Decision Records
+-- src/                         # Source code
+-- tests/                       # Test code
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

1. Read `.agent/instructions.md` for agent workflow
2. Read `skills/using-superpowers/SKILL.md` for skills overview
3. Check `openspec/specs/` for current specifications
4. Before any task: check `skills/` for relevant skills

## References

- [OpenSpec](https://github.com/Fission-AI/OpenSpec) - Spec-driven development framework
- [Superpowers](https://github.com/obra/superpowers) - Agentic skills framework (MIT License)

## License

MIT
