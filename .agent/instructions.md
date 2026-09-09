# Agent Instructions

You are an AI coding agent working on **my-first-project**.

## Session Startup

1. Read `.harness/config.md` for project constraints and quality gates
2. Read `skills/using-superpowers/SKILL.md` for skills system overview
3. Check `openspec/changes/` for in-flight changes
4. Check `openspec/specs/` for current specifications

## Core Workflow

### Before Any Task
- Check `skills/` for relevant skills -- they are MANDATORY workflows
- Read the skill BEFORE proceeding (not after, not "while working")
- If the task involves implementation, the test-driven-development skill is REQUIRED

### The Development Loop

```
1. BRAINSTORM  -> Classify (spike/bounded/architectural), refine idea through questions
2. SPEC        -> Write specs in openspec/specs/ or propose change
3. PLAN        -> Write plan with 2-5 min tasks in openspec/changes/<name>/tasks.md
4. WORKTREE    -> Create isolated branch (if needed)
5. IMPLEMENT   -> TDD: test first, then code, then refactor (one subagent per task)
6. REVIEW      -> Check against plan and specs between tasks
7. VERIFY      -> Run full test suite, verify requirements met with fresh evidence
8. ARCHIVE     -> Move completed change to openspec/changes/archive/
```

## OpenSpec Conventions

### Change Structure
Each change lives in `openspec/changes/<change-name>/`:
- `proposal.md` -- why we're doing this, what's changing
- `specs/` -- requirements and scenarios
- `design.md` -- technical approach
- `tasks.md` -- implementation checklist

### Spec Format
Plain Markdown with concrete scenarios:

```markdown
### Requirement: <Name>
The system SHALL <behavior>.

#### Scenario: <Name>
- **WHEN** <trigger>
- **THEN** <outcome>
```

## Superpowers Skills

Skills are in `skills/<skill-name>/SKILL.md` (flat structure). Each skill is a mandatory workflow — invoke BEFORE any action, not as documentation after the fact.

| Category | Skills | Key Rules |
|----------|--------|-----------|
| Process | brainstorming, writing-plans, executing-plans, subagent-driven-development | Classify ideas, plan in 2-5 min tasks, fresh subagent per task |
| Testing | test-driven-development | NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST |
| Debugging | systematic-debugging, verification-before-completion | 4-phase root cause, no completion without fresh evidence |
| Review | requesting-code-review, receiving-code-review | Technical verification, no performative agreement |
| Git | using-git-worktrees, finishing-a-development-branch | Isolated workspaces, verify tests before merge |
| Meta | using-superpowers, writing-skills, dispatching-parallel-agents | Invoke skills first, TDD for skill creation |

### Supporting Reference Files

Many skills include supporting files loaded on demand:
- `systematic-debugging/` has root-cause-tracing.md, defense-in-depth.md, condition-based-waiting.md
- `subagent-driven-development/` has prompt templates for implementer, reviewer, and re-review
- `test-driven-development/` has writing-good-tests.md
- `brainstorming/` has spec-document-reviewer-prompt.md
- `writing-plans/` has plan-document-reviewer-prompt.md
- `requesting-code-review/` has code-reviewer.md

## TDD Enforcement

- NEVER write code before a failing test exists
- If you catch yourself writing code before tests, DELETE it
- RED -> GREEN -> REFACTOR is the only workflow
- Every commit should have a corresponding test
- This applies to ALL implementation, including skill creation

## Quality Standards

- YAGNI: You Aren't Gonna Need It
- DRY: Don't Repeat Yourself
- Keep functions small and focused
- Write descriptive commit messages
- Update specs when implementation reveals changes
- Verify with evidence, not assumptions
