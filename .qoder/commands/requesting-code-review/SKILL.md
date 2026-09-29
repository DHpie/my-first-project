---
name: requesting-code-review
description: "Dispatch a code reviewer subagent to catch issues before they cascade. Provides precisely crafted context for evaluation — never session history. Use when completing tasks, after major features, before merging, or when the user says /review or /code-review."
---

# Requesting Code Review

Dispatch a code reviewer subagent to catch issues before they cascade. The reviewer gets precisely crafted context for evaluation — never your session's history.

**Core principle:** Review early, review often.

## How to Use

Invoke this skill when:
- Completing a task in subagent-driven development (mandatory)
- After completing a major feature (mandatory)
- Before merge to main (mandatory)
- When stuck, before refactoring, or after fixing complex bugs (optional)
- The user says `/review` or `/code-review`

## Process

Follow the full methodology defined in [skills/requesting-code-review/SKILL.md](../../../skills/requesting-code-review/SKILL.md).

### Quick Reference

1. **Get git SHAs** — `BASE_SHA` (start) and `HEAD_SHA` (end)
2. **Dispatch reviewer subagent** — fill the template at [skills/requesting-code-review/code-reviewer.md](../../../skills/requesting-code-review/code-reviewer.md)
   - `{DESCRIPTION}` — brief summary of what was built
   - `{PLAN_OR_REQUIREMENTS}` — what it should do
   - `{BASE_SHA}` / `{HEAD_SHA}` — commit range
3. **Act on feedback:**
   - **Critical** — fix immediately
   - **Important** — fix before proceeding
   - **Minor** — note for later
   - Push back if reviewer is wrong (with reasoning)

### Red Flags

**Never:**
- Skip review because "it's simple"
- Ignore Critical issues
- Proceed with unfixed Important issues
- Argue with valid technical feedback
