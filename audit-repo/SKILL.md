---
name: audit-repo
description: Skeptical, evidence-based audit of a codebase to find bugs, incomplete or stub code, fake placeholders, hardcoded or faked results, broken wiring, fake tests, and gaps between what the project claims (README, docs, comments) and what the code actually does. Use this whenever the user wants to audit, review, sanity-check, or "reality-check" a repo or half-finished project, asks what actually works or is fake, wants to find TODOs, stubs, mocks, dead code or hardcoded values, or asks "is this project really done / does it do what it says", even if they never say the word "audit".
---

# Audit Repo

Audit the codebase as a skeptical senior reviewer. The point of this skill is to replace the project's *self-description* (README, comments, function names, commit messages) with *verified facts*. Half-finished projects, especially AI-assisted ones, tend to look more complete than they are: functions named `calculate_x` that return a constant, tests that mock the thing under test, features documented but never wired up. Assume nothing works until you have read the implementation or run it.

## Ground rules

- **Read-only.** Do not modify, create, or delete project files during the audit. The only file you may write is the final report, and only if the user asks for one (default name `AUDIT.md`). If you are in a mode that allows edits, still don't make them; fixing comes after the user has seen the report.
- **Evidence or it didn't happen.** Every finding cites `path:line`. If you can't point to a line, it isn't a finding. If you suspect something but can't confirm, label it `UNVERIFIED` and say what would confirm it.
- **No generic advice.** Don't pad with best practices that aren't tied to a real issue in this code. A short, true report beats a long, vague one.
- **Be blunt.** The user wants the real state of the project, not reassurance. Say "this feature is fake" when it is.
- **Don't trust, verify.** A docstring saying "retries 3 times" means nothing until you've seen the retry loop. A passing test means nothing until you've seen what it actually asserts.

## Workflow

### Phase 1: Map the project

1. List the directory tree (skip `node_modules`, `.git`, `venv`, `dist`, `build`, vendored code) and identify the stack, entry points, config files, and how to build/run/test.
2. Run the sweep script to get a fast first pass over suspicious patterns. It is a lead generator, not a verdict; every hit still needs reading in context:
   ```bash
   bash <skill-path>/scripts/sweep.sh <repo-root>
   ```
3. Read the README, docs, and top-level comments and write down every **claim**: each feature, capability, integration, or guarantee the project advertises. You'll check these in Phase 3.

### Phase 2: Hunt for problems, file by file

Work through the source directory by directory, keeping a running findings list so nothing gets dropped on large repos. For big repos, use subagents (if available) to audit top-level directories in parallel, then merge.

Look for the eight problem categories below. `references/checklist.md` has the detailed signals for each; read it before starting so you know what to look for in this stack.

1. **Bugs**: logic errors, off-by-one, wrong conditions, unhandled errors, missing `await`, null/undefined access, wrong types, bad imports, resource leaks, races.
2. **Incomplete code**: TODO/FIXME markers, empty or `pass` bodies, `NotImplementedError`, stub classes, near-empty files, functions never called, dead code.
3. **Fake placeholders**: lorem ipsum, dummy/sample data presented as real, mock responses in non-test code, `example.com`, fake keys, placeholder UI text.
4. **Hardcoded results**: functions returning fixed values instead of computing, special-casing of test inputs, fake delays simulating work, random data posing as real output, hardcoded credentials/paths/URLs/ports, tests asserting against hardcoded values.
5. **Claims vs reality**: grade every claim from Phase 1 (see below).
6. **Broken wiring**: unregistered routes, components never rendered, config read but never used, env vars referenced but undefined, imports of nonexistent modules, frontend/backend endpoint mismatches, models without migrations.
7. **Fake or weak tests**: empty, always-pass, over-mocked, skipped, or missing for core logic.
8. **Security and hygiene**: committed secrets, injection, missing auth checks, swallowed exceptions, missing/unused/unpinned dependencies.

### Phase 3: Verify by running

Reading finds a lot, but running settles arguments. Do this safely:

- Install dependencies, then build, lint, type-check, and run the test suite. Capture real output and error messages.
- If the app can be started without side effects (no real payments, emails, destructive DB operations, or calls to paid APIs), start it and exercise the main flow. Note what crashes, hangs, or silently does nothing.
- If running is unsafe or impossible (missing credentials, external services), say so and mark affected findings `UNVERIFIED` rather than guessing.
- Installing dependencies and generating build artifacts is fine; just don't edit tracked source files.

**Grading each claim** from Phase 1:

| Status | Meaning |
|---|---|
| REAL | Fully implemented and verified (read and/or run) |
| PARTIAL | Works for some cases or paths; say which are missing |
| FAKE | Looks implemented but is hardcoded, mocked, or simulated |
| MISSING | Claimed but no implementation exists |
| UNVERIFIED | Can't confirm either way; state what's needed |

### Phase 4: Report

Use the structure in `references/report-template.md`. In short: honest summary with a rough completion estimate, claims-vs-reality table, issues grouped by severity, placeholder/hardcoded inventory, incomplete/dead files, what verifiably works, and a prioritized top-10 fix plan.

Keep the report ordered by importance, not by file order. Put what's broken and what's fake before what's merely untidy. Saying what *does* work matters too: it tells the user what they can safely build on.

If the user asked for the report in a file, write it to `AUDIT.md` (or the name they gave) and mention that a fresh session can fix issues one severity tier at a time from it.

## Severity guide

- **Critical**: the core feature doesn't work, data loss or security exposure, project can't build or start, or a headline claim is fake.
- **High**: a significant feature is broken or partial, tests give false confidence, or secrets are committed.
- **Medium**: bugs in secondary paths, notable dead code, missing error handling, config that does nothing.
- **Low**: cleanup, naming, minor inconsistencies.

## Follow-ups

- After the user fixes things, a **re-audit** should cover only files changed since the last audit and confirm each issue is *actually resolved*, not just hidden (e.g. a TODO comment deleted but the stub left in place, a failing test deleted instead of fixed).
- If the user asks to fix findings, work from the report in priority order and re-run Phase 3 checks after each fix.
