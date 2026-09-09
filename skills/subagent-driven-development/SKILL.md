---
name: subagent-driven-development
description: Use when executing implementation plans with independent tasks in the current session
---

# Subagent-Driven Development

Execute plan by dispatching a fresh implementer subagent per task, a task review (spec compliance + code quality) after each, and a broad whole-branch review at the end.

**Why subagents:** You delegate tasks to specialized agents with isolated context. By precisely crafting their instructions and context, you ensure they stay focused and succeed at their task. They should never inherit your session's context or history — you construct exactly what they need. This also preserves your own context for coordination work.

**Core principle:** Fresh subagent per task + task review (spec + quality) + broad final review = high quality, fast iteration

**Continuous execution:** Do not pause to check in with your human partner between tasks. Execute all tasks from the plan without stopping. The only reasons to stop are: an irreversible or destructive operation; a security-sensitive action; a side effect outside this worktree; and a plan so broken that every path forward is a guess.

**Rulings, not stalls.** A running plan does not wait on a human. Conflicts,
ambiguities, plan defects — decide them. The spec is the binding authority,
the plan is its argument, and your judgment settles what neither answers.
Record every decision in the ledger as `Ruling: <what you decided> — <why> — <what it costs if wrong>`, and keep going.

## When to Use

**vs. Executing Plans (parallel session):**
- Same session (no context switch)
- Fresh subagent per task (no context pollution)
- Review after each task (spec compliance + code quality), broad review at the end
- Faster iteration (no human-in-loop between tasks)

## The Process

### Setup

Ensure the work happens in an isolated workspace: use using-git-worktrees to create one or verify the existing one. Never start implementation on a main/master branch without your human partner's explicit consent.

Read the plan once, note its context and Global Constraints, and create a todo per task. If the plan names a Spec, read that too: the spec is the authority the plan argues from.

Before dispatching Task 1, scan the plan once for conflicts:
- Tasks that contradict each other or the plan's Global Constraints
- Anything the plan explicitly mandates that the review rubric treats as a defect

### 1. Dispatch the Implementer

Record BASE (`git rev-parse HEAD`) before dispatching.

- **Task brief:** Compose a dispatch containing: (1) one line on where this task fits in the project; (2) the task requirements with exact values; (3) interfaces and decisions from earlier tasks; (4) your resolution of any ambiguity; (5) the report expectations.
- A dispatch prompt describes one task, not the session's history. A fresh subagent needs its task, the interfaces it touches, and the global constraints. Nothing else.
- Never dispatch multiple implementation subagents in parallel (conflicts).

Template: [implementer-prompt.md](implementer-prompt.md)

### 2. Handle the Report

Implementer subagents report one of four statuses:

**DONE:** Generate the review, then dispatch the task reviewer.

**DONE_WITH_CONCERNS:** Read the concerns before proceeding. If about correctness or scope, address before review.

**NEEDS_CONTEXT:** Provide the missing context and re-dispatch.

**BLOCKED:** Assess the blocker:
1. Context problem → provide more context, re-dispatch
2. Needs more reasoning → re-dispatch with more capable model
3. Task too large → break into smaller pieces
4. Plan is wrong → rule on correction, re-dispatch

### 3. Review the Task

- Hand the reviewer the diff (git diff with context)
- The task reviewer gets: the task brief, the report, and the diff
- Do not pre-judge findings for the reviewer

Template: [task-reviewer-prompt.md](task-reviewer-prompt.md)

### 4. The Fix Loop

The loop triggers when the review reports spec issues, any Critical or Important finding.

**Rounds 1-3** — resume the original implementer with open findings.

**Rounds 4-5** — dispatch a fresh implementer with the findings and more context.

**Every round:** the implementer fixes, re-runs tests, and reports back. Then dispatch a scoped re-review.

Template: [re-review-prompt.md](re-review-prompt.md)

### 5. Complete the Task

When the review comes back clean, mark the task complete and move on.

## Final Review

After all tasks, dispatch a final whole-branch code review using requesting-code-review's template. Point it at any deferred items from the task reviews.

If the final review returns findings, dispatch ONE fix subagent with the complete findings list. Then run one scoped re-review.

## Finish

Use finishing-a-development-branch.

## Common Rationalizations

| Excuse | Reality |
|--------|---------|
| "Close enough on spec compliance" | Reviewer found spec gaps = not done. Fix or adjudicate. |
| "I'll fix it myself, dispatching is overhead" | Controller fixes pollute your context and skip review. Resume the implementer. |
| "One more round will converge" | Past the cap, rounds don't converge. Adjudicate and route. |
| "The fix was small, skip the re-review" | Unreviewed fixes are how regressions land. Every round ends with a scoped re-review. |
| "Reviews slow the loop down" | The loop without reviews is just unverified churn. |
