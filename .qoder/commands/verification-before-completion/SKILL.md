---
name: verification-before-completion
description: "Enforce evidence-before-claims discipline: run verification commands and confirm output before making any success claims. Use when about to claim work is complete, fixed, or passing, before committing, creating PRs, or moving to the next task. Also invoke as /verify."
---

# Verification Before Completion

**Core principle:** Evidence before claims, always.

**Iron law:** NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE.

If you haven't run the verification command in this message, you cannot claim it passes.

## How to Use

Invoke this skill when:
- About to claim work is complete, fixed, or passing
- Before committing, creating PRs, or moving to next task
- The user says `/verify` or `/verification`

## Process

Follow the full methodology defined in [skills/verification-before-completion/SKILL.md](../../../skills/verification-before-completion/SKILL.md).

### The Gate Function

1. **IDENTIFY** — What command proves this claim?
2. **RUN** — Execute the FULL command (fresh, complete)
3. **READ** — Full output, check exit code, count failures
4. **VERIFY** — Does output confirm the claim?
   - If NO: State actual status with evidence
   - If YES: State claim WITH evidence
5. **ONLY THEN** — Make the claim

Skip any step = lying, not verifying.

### Common Failures

| Claim | Requires | Not Sufficient |
|-------|----------|----------------|
| Tests pass | Test command output: 0 failures | Previous run, "should pass" |
| Linter clean | Linter output: 0 errors | Partial check, extrapolation |
| Build succeeds | Build command: exit 0 | Linter passing, logs look good |
| Bug fixed | Test original symptom: passes | Code changed, assumed fixed |
| Requirements met | Line-by-line checklist | Tests passing |

### Red Flags — STOP

- Using "should", "probably", "seems to"
- Expressing satisfaction before verification ("Great!", "Done!")
- About to commit/push/PR without verification
- Relying on partial verification
- Thinking "just this once"
