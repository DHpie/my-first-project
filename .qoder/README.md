# .qoder/ - Qoder Agent Integration

This directory is the Qoder-specific integration point for OpenSpec.

OpenSpec generates slash commands and skills into this directory when configured with `--tools qoder`.

## Structure

```
.qoder/
  commands/                # Slash commands (invoked via /opsx:*)
    opsx/
      explore.md           # /opsx:explore - Brainstorm and explore ideas
      propose.md           # /opsx:propose - Create a new change proposal
      apply.md             # /opsx:apply - Implement tasks from a change
      archive.md           # /opsx:archive - Archive a completed change
      sync.md              # /opsx:sync - Sync delta specs to main specs
      update.md            # /opsx:update - Update an existing change
  skills/                  # Skill definitions (loaded by agent context)
    openspec-explore/
    openspec-propose/
    openspec-apply-change/
    openspec-archive-change/
    openspec-sync-specs/
    openspec-update-change/
```

## Commands vs Skills

| Type | Location | Purpose |
|------|----------|---------|
| **Commands** | `commands/opsx/` | Slash commands users invoke (e.g., `/opsx:propose`) |
| **Skills** | `skills/openspec-*/` | Detailed skill definitions loaded into agent context |

Commands are the entry points; skills provide the underlying methodology.

## Integration Points

| Component | Location | Purpose |
|-----------|----------|---------|
| Harness config | `.harness/config.md` | Agent behavior constraints, quality gates, lifecycle phases |
| Agent instructions | `.agent/instructions.md` | Workflow instructions, skill reference table, TDD enforcement |
| Superpowers skills | `skills/` | 13 mandatory workflow skills with supporting reference files |
| OpenSpec artifacts | `openspec/` | Spec-driven development: specs, changes, proposals, archive |

## Setup

```bash
npm install -g @fission-ai/openspec@latest
openspec init --tools qoder    # Non-interactive setup
openspec update                # Refresh after OpenSpec version upgrade
```

## How It Works Together

1. **Session starts** → Agent reads `.harness/config.md` and `skills/using-superpowers/SKILL.md`
2. **Task arrives** → Agent checks `skills/` for relevant mandatory workflow
3. **Explore** → `/opsx:explore` to brainstorm and refine ideas
4. **Propose** → `/opsx:propose` to create change with proposal + specs + design + tasks
5. **Implement** → TDD enforced by test-driven-development skill, tasks tracked via `/opsx:apply`
6. **Verify** → verification-before-completion requires fresh evidence
7. **Archive** → `/opsx:archive` moves completed change to `openspec/changes/archive/`
