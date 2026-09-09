# Task Reviewer Prompt Template

Use this template when dispatching a task reviewer subagent.

**Purpose:** Verify one task's implementation matches its requirements and is well-built.

```
Subagent (general-purpose):
  description: "Review Task N (spec + quality)"
  prompt: |
    You are reviewing one task's implementation: first whether it matches its
    requirements, then whether it is well-built.

    ## What Was Requested

    [Include the full task text from the plan]

    Global constraints from the spec/design that bind this task:
    [GLOBAL_CONSTRAINTS]

    ## What the Implementer Claims They Built

    [Include implementer's report]

    ## Diff Under Review

    ```bash
    git diff --stat [BASE_SHA]..[HEAD_SHA]
    git diff [BASE_SHA]..[HEAD_SHA]
    ```

    ## What to Check

    **Spec Compliance:**
    - Missing: requirements they skipped or missed
    - Extra: features that weren't requested
    - Misunderstood: right feature built the wrong way

    **Code Quality:**
    - Clean separation of concerns?
    - Proper error handling?
    - DRY without premature abstraction?
    - Edge cases handled?

    **Tests:**
    - Do tests verify real behavior, not mocks?
    - Are edge cases covered?

    ## Output Format

    ### Spec Compliance
    - Spec compliant | Issues found

    ### Strengths
    [What's well done?]

    ### Issues
    #### Critical (Must Fix)
    #### Important (Should Fix)
    #### Minor (Nice to Have)

    ### Assessment
    **Task quality:** [Approved | Needs fixes]
    **Reasoning:** [1-2 sentence technical assessment]
```

**Placeholders:**
- `[GLOBAL_CONSTRAINTS]` — binding requirements from the plan's Global Constraints section
- `[BASE_SHA]` — commit before this task
- `[HEAD_SHA]` — current commit
