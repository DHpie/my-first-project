---
name: using-git-worktrees
description: "Set up an isolated git worktree workspace before feature work or plan execution. Detects existing isolation, prefers native worktree tools, falls back to manual git worktrees. Use when starting feature work that needs workspace isolation, before executing implementation plans, or when the user says /worktree."
---

# Using Git Worktrees

Ensure work happens in an isolated workspace. Prefer native worktree tools. Fall back to manual git worktrees only when no native tool is available.

**Core principle:** Detect existing isolation first → use native tools → fall back to git. Never fight the harness.

## How to Use

Invoke this skill when:
- Starting feature work that needs isolation from current workspace
- Before executing implementation plans
- The user says `/worktree` or `/git-worktree`

## Process

Follow the full methodology defined in [skills/using-git-worktrees/SKILL.md](../../../skills/using-git-worktrees/SKILL.md).

### Quick Reference

1. **Detect existing isolation** — check `GIT_DIR != GIT_COMMON` (guard against submodule false positive)
2. **Create workspace** — prefer native tools (Step 1a), fall back to `git worktree add` (Step 1b)
3. **Directory selection** — check for `.worktrees/` or `worktrees/`, default to `.worktrees/`
4. **Safety** — verify `.worktrees/` is gitignored; if not, add to `.gitignore` + commit
5. **Project setup** — auto-detect and run `npm install` / `pip install` / `go mod download`
6. **Verify baseline** — run tests to ensure workspace starts clean

### Common Rationalizations

| Excuse | Reality |
|--------|---------|
| "Obviously not in a worktree — no need to check" | Run Step 0. Detection commands settle it. |
| "Directory is surely ignored already" | Run `git check-ignore`. |
| "Baseline tests can wait" | A dirty baseline makes every later failure ambiguous. |
