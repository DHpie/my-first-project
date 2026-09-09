# OpenSpec

Spec-Driven Development (SDD) artifacts for this project. OpenSpec ensures agreement on specifications before writing code.

## Structure

```
openspec/
  config.yaml          # Project configuration (schema: spec-driven)
  specs/               # Feature specifications (requirements and scenarios)
  changes/             # In-flight change proposals
    <change-name>/     # Each change contains:
      proposal.md      #   Why and what is changing
      specs/           #   Requirements and scenarios
      design.md        #   Technical approach
      tasks.md         #   Implementation checklist
    archive/           # Completed and archived changes
```

## Workflow

1. **Explore** - Think through ideas, understand requirements
2. **Propose** - Create a change with proposal, specs, design, and tasks
3. **Apply** - Implement tasks following TDD workflow
4. **Archive** - Move completed changes to `changes/archive/`

## Core Principles

- **Fluid, not rigid** - Any artifact can be updated at any time
- **Agree before building** - Specs define what to build before code defines how
- **Concrete scenarios** - Every requirement has testable scenarios
- **Traceability** - Changes link proposals to specs to implementation

## Spec Format

```markdown
### Requirement: <Name>
The system SHALL <behavior>.

#### Scenario: <Name>
- **WHEN** <trigger>
- **THEN** <outcome>
```

## Setup

```bash
npm install -g @fission-ai/openspec@latest
cd my-first-project
openspec init
```

## References

- [OpenSpec GitHub](https://github.com/Fission-AI/OpenSpec) - Framework documentation
- [OpenSpec Specification](https://github.com/Fission-AI/OpenSpec/blob/main/docs/specification.md) - Full spec format reference
