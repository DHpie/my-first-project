---
name: writing-plans
description: "Write comprehensive implementation plans from specs or requirements before touching code. Produces bite-sized TDD tasks with exact file paths, code snippets, and test commands. Use when you have a spec or requirements for a multi-step task, after brainstorming/approved design, and before implementation."
---

# Writing Plans

Write comprehensive implementation plans assuming the engineer has zero context. Document everything: which files to touch, code, testing, docs, how to verify. Deliver the whole plan as bite-sized tasks. DRY. YAGNI. TDD. Frequent commits.

## How to Use

Invoke this skill when:
- You have an approved spec or requirements and need to plan implementation
- The user says `/writing-plans` or `/plan`
- After brainstorming's architectural path completes with an approved design

## Process

Follow the full methodology defined in [skills/writing-plans/SKILL.md](../../../skills/writing-plans/SKILL.md).

### Quick Reference

1. **Scope check** — if spec covers multiple subsystems, suggest separate plans
2. **Map file structure** — list files to create/modify with responsibilities
3. **Right-size tasks** — smallest unit with its own test cycle, independently testable
4. **Bite-sized steps** — each step is one action (2-5 min): write test, run, implement, commit
5. **No placeholders** — every step must contain actual content, never "TBD" or "implement later"
6. **Self-review** — spec coverage, placeholder scan, type consistency
7. **Execution handoff** — offer subagent-driven (recommended) or inline execution

### Plan Document Header (required)

Every plan starts with: Goal, Architecture, Tech Stack, Spec path, Global Constraints.

### Task Structure (required)

Each task includes: Files (Create/Modify/Test), Interfaces (Consumes/Produces), then TDD steps with actual code blocks.

### Save plans to: `docs/superpowers/plans/YYYY-MM-DD-<feature-name>.md`
(User preferences for plan location override this default)
