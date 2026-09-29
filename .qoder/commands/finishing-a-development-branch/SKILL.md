---
name: finishing-a-development-branch
description: "Complete a development branch: verify tests, detect environment, present integration options (merge locally, push PR, or keep as-is), execute choice, and clean up workspace. Use when implementation is complete, all tests pass, and you need to decide how to integrate the work. Also invoke as /finish or /finish-branch."
---

# Finishing a Development Branch

Verify tests → Detect environment → Present options → Execute choice → Clean up.

## How to Use

Invoke this skill when:
- Implementation is complete and all tests pass
- Need to decide how to integrate the work
- The user says `/finish` or `/finish-branch`

## Process

Follow the full methodology defined in [skills/finishing-a-development-branch/SKILL.md](../../../skills/finishing-a-development-branch/SKILL.md).

### Quick Reference

1. **Verify tests** — run full suite; if fail, report and stop (no menu)
2. **Detect environment** — check `GIT_DIR` vs `GIT_COMMON` to determine menu and cleanup strategy
3. **Determine base branch** — confirm fork point before merging (merging into wrong base is expensive)
4. **Present options:**
   - Normal repo / named branch: 3 options (merge locally, push PR, keep as-is)
   - Detached HEAD: 2 options (push PR, keep as-is)
   - Discard only when explicitly requested by user
5. **Execute choice** — merge + verify, or push + create PR, or preserve
6. **Cleanup workspace** — remove worktree if we own it; never force-remove on own initiative

### Quick Reference Table

| Option | Merge | Push | Keep Worktree | Cleanup Branch |
|--------|-------|------|---------------|----------------|
| 1. Merge locally | yes | - | - | yes |
| 2. Create PR | - | yes | yes | - |
| 3. Keep as-is | - | - | yes | - |
| Discard (explicit only) | - | - | - | yes (force) |

### Common Rationalizations

| Excuse | Reality |
|--------|---------|
| "Tests passed earlier" | Run the suite on the tree you are about to integrate. |
| "They obviously want it merged" | Integration is the user's decision. Present the menu and wait. |
| "The base branch is obviously main" | Confirm the fork point. Merging into wrong base is expensive. |
