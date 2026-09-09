# Harness Configuration

Configures the AI coding agent's behavior, constraints, and lifecycle controls.

## Agent Identity

- **Project**: my-first-project
- **Methodology**: Harness + OpenSpec + Superpowers
- **Primary Language**: (configure your primary language here)

## Session Startup

At the start of each session:
1. Read this file (`.harness/config.md`)
2. Read `skills/using-superpowers/SKILL.md` — the skills system entry point
3. Check `openspec/changes/` for in-flight changes
4. Check `openspec/specs/` for current specifications
5. Load any skill referenced by the current task context

## Behavioral Constraints

### Before Writing Code
- ALWAYS check `skills/` for relevant skills before ANY task
- ALWAYS read existing specs in `openspec/specs/` for context
- NEVER jump into implementation without a spec or plan
- Invoke using-superpowers skill first — it governs all other skills

### During Implementation
- Follow TDD: failing test -> minimal code -> pass -> refactor
- Keep tasks small (2-5 minutes each) per writing-plans skill
- Run tests after every change
- Commit frequently with meaningful messages
- Use systematic-debugging when tests fail unexpectedly (4-phase process)

### After Implementation
- Run full test suite before declaring completion
- Use `verification-before-completion` skill — requires fresh evidence
- Verify against the original spec/proposal
- Request code review using `requesting-code-review` skill
- Archive completed changes per OpenSpec workflow

## Lifecycle Phases

1. **Brainstorm** - Classify idea (spike/bounded/architectural), refine through questions
2. **Propose** - Create change in `openspec/changes/<name>/` with:
   - `proposal.md` -- why and what
   - `specs/` -- requirements and scenarios
   - `design.md` -- technical approach
   - `tasks.md` -- implementation checklist
3. **Plan** - Write detailed plan with bite-sized tasks (2-5 min each) inside `openspec/changes/<name>/tasks.md`
4. **Worktree** - Create isolated workspace if needed
5. **Implement** - Execute using TDD with subagent-driven development
6. **Review** - Code review against plan and specs
7. **Verify** - Fresh verification evidence required before completion claims
8. **Archive** - Move to `openspec/changes/archive/`

## Quality Gates

- [ ] All tests pass (with evidence, not assumptions)
- [ ] Code follows project conventions
- [ ] Specs are up to date
- [ ] No unresolved TODOs or placeholders
- [ ] Changes are documented in OpenSpec
- [ ] Verification-before-completion checklist satisfied
- [ ] Code review requested and feedback addressed

## Tool Preferences

- **Package Manager**: (npm / pnpm / yarn / bun)
- **Test Framework**: (jest / vitest / pytest / etc.)
- **Linter**: (eslint / ruff / etc.)
- **Formatter**: (prettier / black / etc.)

## Skills Reference

All 13 mandatory skills are in `skills/<skill-name>/SKILL.md`. Each skill directory may contain supporting reference files:

| Skill | Supporting Files |
|-------|-----------------|
| brainstorming | spec-document-reviewer-prompt.md |
| dispatching-parallel-agents | — |
| executing-plans | — |
| finishing-a-development-branch | — |
| receiving-code-review | — |
| requesting-code-review | code-reviewer.md |
| subagent-driven-development | implementer-prompt.md, task-reviewer-prompt.md, re-review-prompt.md |
| systematic-debugging | root-cause-tracing.md, defense-in-depth.md, condition-based-waiting.md |
| test-driven-development | writing-good-tests.md |
| using-git-worktrees | — |
| using-superpowers | — |
| verification-before-completion | — |
| writing-plans | plan-document-reviewer-prompt.md |
| writing-skills | — |
