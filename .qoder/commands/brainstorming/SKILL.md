---
name: brainstorming
description: "Collaborative brainstorming for creative and implementation work. Classifies tasks into Spike/Bounded/Architectural paths, explores requirements through dialogue, and enforces approval gates before any implementation. Use when starting new features, building components, adding functionality, or modifying behavior."
---

# Brainstorming

Help turn ideas into fully formed designs and specs through natural collaborative dialogue.

## How to Use

Invoke this skill when:
- Starting any creative or implementation work
- The user says `/brainstorming` or `/brainstorm`
- A new feature, component, or behavior change is requested

## Process

Follow the full methodology defined in [skills/brainstorming/SKILL.md](../../../skills/brainstorming/SKILL.md).

### Quick Reference

1. **Classify the task** — announce which path before proceeding:
   - **Spike** — feasibility probe, output is an answer (not keepable code)
   - **Bounded** — well-scoped change to existing code, short design in chat
   - **Architectural** — new projects/subsystems, full design process with spec doc

2. **Explore context** — check files, docs, recent commits

3. **Ask clarifying questions** — one at a time, prefer multiple choice

4. **Present design** — scaled to complexity, get explicit approval

5. **Hard gate** — do NOT write any code until the user approves the design

### When in doubt, take the heavier path. Complexity discovered mid-task upgrades the path — never downgrades.
