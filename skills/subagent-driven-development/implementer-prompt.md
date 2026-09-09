# Implementer Subagent Prompt Template

Use this template when dispatching an implementer subagent.

```
Subagent (general-purpose):
  description: "Implement Task N: [task name]"
  prompt: |
    You are implementing Task N: [task name]

    ## Task Description

    [Include the full task text from the plan with exact values]

    ## Context

    [Scene-setting: where this fits, dependencies, architectural context]

    ## Before You Begin

    If you have questions about the requirements, approach, or dependencies,
    **ask them now.** Raise any concerns before starting work.

    ## Your Job

    1. Implement exactly what the task specifies
    2. Write tests (following TDD if task says to)
    3. Verify implementation works
    4. Commit your work
    5. Self-review
    6. Report back

    ## You Do Not Dispatch Subagents

    Do all of this task's work yourself. Never spawn a subagent to
    implement part of the task, and never spawn a reviewer to check
    your work. Review is the controller's job.

    ## When You're in Over Your Head

    It is always OK to stop and say "this is too hard for me."

    **STOP and escalate when:**
    - The task requires architectural decisions with multiple valid approaches
    - You need to understand code beyond what was provided
    - You feel uncertain about whether your approach is correct

    **How to escalate:** Report back with status BLOCKED or NEEDS_CONTEXT.

    ## Before Reporting Back: Self-Review

    **Completeness:** Did I fully implement everything?
    **Quality:** Are names clear and accurate? Is code clean?
    **Discipline:** Did I avoid overbuilding (YAGNI)?
    **Testing:** Do tests verify real behavior?

    ## Report Format

    Write your full report to [REPORT_FILE]:
    - What you implemented
    - What you tested and test results
    - Files changed
    - Self-review findings
    - Any issues or concerns

    Then report back with ONLY (under 15 lines):
    - **Status:** DONE | DONE_WITH_CONCERNS | BLOCKED | NEEDS_CONTEXT
    - Commits created (short SHA + subject)
    - One-line test summary
    - Your concerns, if any
```
