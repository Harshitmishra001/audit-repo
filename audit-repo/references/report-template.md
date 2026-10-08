# Report template

Use this structure, in this order. Omit a section only if it genuinely has nothing in it (and say so in one line rather than silently dropping it). Every finding needs `path:line`.

```markdown
# Audit Report: <project name>

## Summary
3-5 lines. Honest overall state, e.g. "Roughly 30% working prototype: the UI and routing are real, the core analysis engine is hardcoded, and there are no meaningful tests." Include what stack and entry points were audited and whether the project builds/starts.

## Claims vs Reality
| Feature | Claimed where | Status | Evidence |
|---|---|---|---|
| <feature> | README.md:12 | REAL / PARTIAL / FAKE / MISSING / UNVERIFIED | src/x.py:40, ran: <result> |

## Issues by severity

### Critical
1. **<short title>** (`path:line`): what is wrong, why it matters, suggested fix.

### High
...
### Medium
...
### Low
...

## Placeholders and hardcoded values
Every instance, one per line: `path:line` - what it is (e.g. "returns fixed score 0.87 regardless of input").

## Incomplete and dead files
`path` - one-line reason (empty / stub only / never imported / unreachable).

## Verified by running
What was actually executed and what happened: build, lint, type-check, tests (pass/fail counts), startup, main flow. Include key error output. List what could NOT be run and why.

## What actually works
Things verified (read and/or run) that the user can safely build on.

## Prioritized fix plan
Top 10, in order, each one line, referencing the issue it resolves.
```

Notes:
- Order issues within a severity by impact, not by file.
- Mark anything not confirmed as `UNVERIFIED` and say what's needed to confirm it.
- No generic best-practice filler. If an item isn't tied to something in this code, cut it.
