# Writing Good Tests

**Load this reference when:** writing or changing tests, adding mocks, or adding cleanup/helper methods for tests.

## Overview

A test exists to catch a specific break. Two principles govern everything here:

```
1. Every test names the break it catches
2. Every test exercises the real thing
```

## Principle 1: Name the Break

Before writing the test body, answer: **what production change should make this test fail — and is that change a bug or a decision?**

**Derive expectations independently.** Use literals and hand-checked fixtures:

```typescript
// BAD: Mirror assertion: the same builder computes both sides
const expected = buildSearchQuery({ tag: 'urgent' });
expect(buildSearchQuery({ tag: 'urgent' })).toBe(expected);

// GOOD: Hand-derived literal
expect(buildSearchQuery({ tag: 'urgent' })).toBe('tag:"urgent"');
```

**No change detectors.** If only intentional decisions can fail a test, it fires on redesign and sleeps through bugs. Test the behavior that depends on the decision.

**Behavior, not text.** Assert outputs, side effects, or exit codes — not that source text contains specific lines.

### Gate Function

```
BEFORE writing the test body:
  Name the production change that would make this test fail.

  Cannot name one            -> redesign around an observable behavior
  "The source text changed"  -> run the artifact and assert its effects
  Only intentional decisions -> change detector; test the behavior

  Confirm the expected value is derived without the code under test.
```

## Principle 2: Exercise the Real Thing

**Mock at the right level.** Learn every side effect of the real method before replacing it; mock the slow or external operation and keep what the test depends on real.

**Make doubles specific.** When arguments, call counts, or ordering are part of the contract, assert them.

**Mirror real data completely.** Mock the complete structure as it exists in reality.

**Production classes carry production methods only.** Cleanup that only tests use lives in test utilities, never as methods on the production class.

### Gate Function

```
BEFORE adding a mock or test helper:
  List the real method's side effects; keep the ones the test
  depends on real — mock the slow/external level below them.

  Mock responses mirror the complete real structure.

  A method only tests call lives in test utilities, not production.
```

## The Mutation Check

Before finishing, mentally mutate the production code; at least one test should fail for each realistic mutation:

- Wrong constant or argument
- Wrong branch handler
- Missing state change or side effect
- Empty or default return
- Missing validation for zero, empty, nil, unauthorized, or malformed input

## Quick Reference

| When you... | Do |
|-------------|-----|
| Write any test | Name the break it catches — a bug, not a decision |
| Build an expected value | Derive it by hand; never with the code under test |
| Reach for a dependency test | Test your boundary contract, not their mechanics |
| Want to assert on a mocked element | Test the real component, or unmock it |
| Are about to mock a method | Learn its side effects; mock the slow/external level |
| Need cleanup only tests use | Put it in test utilities |
| Watch mock setup balloon | Switch to an integration test with real components |
| Finish a test file | Run the mutation check |

## Warning Signs

- Setup and assertion share the same object, guaranteeing equality
- The test can fail only through a panic, crash, or missing selector
- The test fails on every intentional change, never on accidental breakage
- Expected values are hidden behind loops, builders, or helpers
- An assertion checks a `*-mock` test ID, or fails if you remove the mock
- Mock setup is more than half the test
