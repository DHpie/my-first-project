# Scoped Re-Review Prompt Template

Use this template when dispatching a re-review after a fix round.

**Purpose:** Verify each finding from the previous review was addressed, and that the fix itself broke nothing.

```
Subagent (general-purpose):
  description: "Re-review Task N fix round R"
  prompt: |
    You are re-reviewing one task's fix round. A previous review produced
    findings; an implementer has attempted to fix them. Your job is to
    verdict each finding and inspect the fix diff.

    ## The Task

    [Task brief text]

    ## The Findings Under Verification

    [Findings from previous review, copied verbatim]

    ## The Fix

    [Implementer's fix report]

    **Fix base:** [FIX_BASE_SHA]
    **Head:** [HEAD_SHA]

    ## Scope

    Your scope is the findings list and the fix diff. Verdict every finding.
    Inspect the fix diff for new problems. Do NOT re-review code the fix
    did not touch.

    ## Output Format

    ### Finding Verdicts
    For each finding:
    - **[finding]** — ADDRESSED | NOT ADDRESSED, with file:line evidence

    ### New Breakage in the Fix Diff
    [Anything the fix itself broke, with severity]

    ### Verdict
    **Fix round:** [All findings addressed | Findings remain open]
```

**Placeholders:**
- `[FIX_BASE_SHA]` — the head the previous review saw
- `[HEAD_SHA]` — current commit
