# Root Cause Tracing

## Overview

Bugs often manifest deep in the call stack. Your instinct is to fix where the error appears, but that's treating a symptom.

**Core principle:** Trace backward through the call chain until you find the original trigger, then fix at the source.

## When to Use

**Use when:**
- Error happens deep in execution (not at entry point)
- Stack trace shows long call chain
- Unclear where invalid data originated

## The Tracing Process

### 1. Observe the Symptom
Note the error message and where it appears.

### 2. Find Immediate Cause
**What code directly causes this?**

### 3. Ask: What Called This?
Trace the call chain upward.

### 4. Keep Tracing Up
**What value was passed?** Where did it come from?

### 5. Find Original Trigger
**Where did the bad value originate?**

## Adding Stack Traces

When you can't trace manually, add instrumentation:

```typescript
// Before the problematic operation
const stack = new Error().stack;
console.error('DEBUG:', { directory, cwd: process.cwd(), stack });
```

## Key Principle

**NEVER fix just where the error appears.** Trace back to find the original trigger.

## Stack Trace Tips

- Use `console.error()` in tests (not logger - may not show)
- Log before the dangerous operation, not after it fails
- Include context: directory, cwd, environment variables, timestamps
- Capture stack: `new Error().stack` shows complete call chain
