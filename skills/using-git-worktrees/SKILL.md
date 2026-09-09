---
name: using-git-worktrees
description: Use when starting feature work that needs isolation from current workspace or before executing implementation plans - ensures an isolated workspace exists
---

# Using Git Worktrees

## Overview

Ensure work happens in an isolated workspace. Prefer your platform's native worktree tools. Fall back to manual git worktrees only when no native tool is available.

**Core principle:** Detect existing isolation first. Then use native tools. Then fall back to git. Never fight the harness.

**Announce at start:** "I'm using the using-git-worktrees skill to set up an isolated workspace."

## Step 0: Detect Existing Isolation

**Before creating anything, check if you are already in an isolated workspace.**

```bash
GIT_DIR=$(cd "$(git rev-parse --git-dir)" 2>/dev/null && pwd -P)
GIT_COMMON=$(cd "$(git rev-parse --git-common-dir)" 2>/dev/null && pwd -P)
BRANCH=$(git branch --show-current)
```

**Submodule guard:** `GIT_DIR != GIT_COMMON` is also true inside git submodules. Before concluding "already in a worktree," verify you are not in a submodule:

```bash
git rev-parse --show-superproject-working-tree 2>/dev/null
```

**If `GIT_DIR != GIT_COMMON` (and not a submodule):** You are already in a linked worktree. Skip to Step 2.

**If `GIT_DIR == GIT_COMMON` (or in a submodule):** You are in a normal repo checkout. Ask for consent before creating a worktree.

## Step 1: Create Isolated Workspace

### 1a. Native Worktree Tools (preferred)

Check if you have a worktree creation tool available. If so, use it and skip to Step 2.

### 1b. Git Worktree Fallback

**Only use this if Step 1a does not apply.**

#### Directory Selection

1. Check instructions for a declared worktree directory preference
2. Check for existing `.worktrees/` or `worktrees/` directory
3. Default to `.worktrees/` at the project root

#### Safety Verification

```bash
git check-ignore -q .worktrees 2>/dev/null || git check-ignore -q worktrees 2>/dev/null
```

If NOT ignored: Add to .gitignore, commit the change, then proceed.

#### Create the Worktree

```bash
path="$LOCATION/$BRANCH_NAME"
git worktree add "$path" -b "$BRANCH_NAME"
cd "$path"
```

## Step 2: Project Setup

Auto-detect and run appropriate setup:

```bash
# Node.js
if [ -f package.json ]; then npm install; fi
# Python
if [ -f requirements.txt ]; then pip install -r requirements.txt; fi
# Go
if [ -f go.mod ]; then go mod download; fi
```

## Step 3: Verify Clean Baseline

Run tests to ensure workspace starts clean. If tests fail: report failures, ask whether to proceed or investigate.

## Quick Reference

| Situation | Action |
|-----------|--------|
| Already in linked worktree | Skip creation (Step 0) |
| In a submodule | Treat as normal repo (Step 0 guard) |
| Native worktree tool available | Use it (Step 1a) |
| No native tool | Git worktree fallback (Step 1b) |
| `.worktrees/` exists | Use it (verify ignored) |
| Directory not ignored | Add to .gitignore + commit |
| Tests fail during baseline | Report failures + ask |

## Common Rationalizations

| Excuse | Reality |
|--------|---------|
| "I'm obviously not in a worktree — no need to check" | Run Step 0. Detection commands settle it. |
| "The worktree directory is surely ignored already" | Run `git check-ignore`. |
| "The workspace is fresh — baseline tests can wait" | A dirty baseline makes every later failure ambiguous. |
