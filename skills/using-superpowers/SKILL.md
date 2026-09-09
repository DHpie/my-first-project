---
name: using-superpowers
description: "Use when starting any conversation - establishes how to find and use skills, requiring skill invocation before ANY response including clarifying questions"
---

# Using Superpowers

<EXTREMELY-IMPORTANT>
If you think there is even a 1% chance a skill might apply to what you are doing, you ABSOLUTELY MUST invoke the skill.

IF A SKILL APPLIES TO YOUR TASK, YOU DO NOT HAVE A CHOICE. YOU MUST USE IT.

This is not negotiable. You cannot rationalize your way out of this.
</EXTREMELY-IMPORTANT>

## The Rule

**Invoke relevant or requested skills BEFORE any response or action** — including clarifying questions, exploring the codebase, or checking files. If it turns out wrong for the situation, you don't have to use it.

**Before entering plan mode:** if you haven't already brainstormed, invoke the brainstorming skill first.

Then announce "Using [skill] to [purpose]" and follow the skill exactly. If it has a checklist, create a todo per item.

## Skill Priority

When multiple skills apply, process skills come first — they set the approach, then implementation skills carry it out. Brainstorming and systematic-debugging are the most common process skills, but the rule holds for any of them.

- "Let's build X" -> brainstorming first, then implementation skills.
- "Fix this bug" -> systematic-debugging first, then domain skills.

## Skills Available

Check the `skills/` directory for all available skills:

| Skill | When to Use |
|-------|-------------|
| brainstorming | Before any creative work |
| writing-plans | After approved spec, before coding |
| executing-plans | Batch execution with checkpoints |
| subagent-driven-development | Fresh subagent per task + review |
| test-driven-development | During any implementation |
| systematic-debugging | Any bug or unexpected behavior |
| verification-before-completion | Before declaring work done |
| requesting-code-review | Between tasks |
| receiving-code-review | When getting feedback |
| using-git-worktrees | Isolated workspace setup |
| finishing-a-development-branch | When tasks complete |
| dispatching-parallel-agents | Concurrent workflows |
| writing-skills | Creating new skills |

## Red Flags

These thoughts mean STOP — you're rationalizing:

| Thought | Reality |
|---------|---------|
| "This is just a simple question" | Questions are tasks. Check for skills. |
| "I need more context first" | Skill check comes BEFORE clarifying questions. |
| "Let me explore the codebase first" | Skills tell you HOW to explore. Check first. |
| "This doesn't need a formal skill" | If a skill exists, use it. |
| "I remember this skill" | Skills evolve. Read current version. |
| "The skill is overkill" | Simple things become complex. Use it. |
| "I'll just do this one thing first" | Check BEFORE doing anything. |
| "This feels productive" | Undisciplined action wastes time. Skills prevent this. |
| "I know what that means" | Knowing the concept != using the skill. Invoke it. |

## User Instructions

User instructions (direct requests) take precedence over skills, which in turn override default behavior. Only skip skill workflows when your human partner has explicitly told you to.
