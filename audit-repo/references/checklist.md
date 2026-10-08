# Detailed audit checklist

Read this before Phase 2. Each section lists concrete signals. These are prompts for where to look, not an exhaustive list: if something smells wrong and isn't here, report it.

## Contents
1. Bugs
2. Incomplete code
3. Fake placeholders
4. Hardcoded results
5. Claims vs reality
6. Broken wiring
7. Fake or weak tests
8. Security and hygiene
9. Stack-specific signals

## 1. Bugs
- Conditions that are always true/false; `=` vs `==`; inverted checks; wrong operator precedence.
- Off-by-one in loops, slices, pagination, ranges.
- Missing `await` / unhandled promises / unawaited coroutines; async functions called as if sync.
- Null/undefined/None access without guards; optional values assumed present.
- Wrong types passed between layers (string vs int ids, dates as strings, snake_case vs camelCase keys).
- Imports that don't resolve; circular imports; wrong relative paths; case-sensitivity issues.
- Resources never closed (files, sockets, DB connections); unbounded growth (caches, listeners, queues).
- Shared mutable state, race conditions, non-atomic read-modify-write.
- Error paths that return success, or catch and continue as if nothing happened.
- Variables shadowed or assigned but never used (often a sign a computation was abandoned).

## 2. Incomplete code
- Markers: `TODO`, `FIXME`, `HACK`, `XXX`, `WIP`, `temporary`, `for now`, `stub`, `later`.
- Bodies that are only `pass`, `...`, `return`, `return None`, `{}`, `return []`, `return true`, or a bare log statement.
- `NotImplementedError`, `throw new Error("not implemented")`, `unimplemented!()`, `todo!()`, `panic("TODO")`.
- Classes/interfaces with methods that all stub out; abstract bases with no real subclass.
- Files that are empty, contain only imports, or only a header comment.
- Functions/exports/components defined but never referenced anywhere (grep for callers).
- Commented-out blocks of real logic that suggest an abandoned approach.
- Feature flags permanently off; code behind `if (false)` / `if 0`.

## 3. Fake placeholders
- `lorem ipsum`, `foo`, `bar`, `baz`, `John Doe`, `Jane Doe`, `test@test.com`, `user@example.com`, `example.com`, `localhost` baked into non-config code, `123456`, `abc123`, `your-api-key-here`, `YOUR_TOKEN`, `changeme`, `xxx`.
- Sample/seed/dummy datasets rendered in the UI or returned from API handlers as if real.
- Mock responses outside test directories (`mockData`, `fakeResponse`, `sampleUsers`, `dummy`).
- UI text like "Coming soon", "Title here", "Description", default template copy from scaffolding tools.
- Placeholder images/URLs (`placehold.it`, `via.placeholder.com`, `picsum`), default favicon/logo from a template.

## 4. Hardcoded results
- Functions whose return value doesn't depend on their inputs; always returning the same dict/number/string.
- Output that is computed but then overwritten by a constant, or a computed result ignored in favor of a literal.
- Branches that special-case specific inputs (test fixtures, demo values, known IDs).
- `setTimeout`/`sleep`/`await delay()` simulating network or processing time, fake progress bars, fake "loading" states.
- `Math.random()`/`random.*` generating metrics, scores, charts, "AI" outputs, or statuses that are presented as real data.
- "Analysis", "AI", "ML" or "scoring" functions that are really `if/else` on keywords or length.
- Hardcoded credentials, tokens, absolute paths (`/Users/...`, `C:\...`), ports, hostnames, model names, file names that should be configurable.
- Tests asserting equality with the same literal the code returns (circular proof).
- Hardcoded success: API handlers that return `{"status": "ok"}` without doing the work.

## 5. Claims vs reality
For each claim in README/docs/comments/package description/CLI help, locate the implementation and answer:
- Does code exist that does this? Is it reachable from an entry point (route, CLI command, UI, scheduled job)?
- Does it use real inputs and produce real outputs, or fixed/mock ones?
- Does it handle failure, or only the happy path shown in the demo?
- Is the integration real (actual SDK/API call with real config), or a wrapper around a stub?
- Are "supports X, Y, Z" lists fully implemented, or is only X real?
- Are docs describing setup steps/commands/env vars that actually exist and work?
Grade REAL / PARTIAL / FAKE / MISSING / UNVERIFIED with `path:line` evidence.

## 6. Broken wiring
- Routes/handlers/controllers defined but not registered with the router/app.
- Components/pages/modules defined but never imported or rendered.
- Config keys documented or read but never used (or used but never defined).
- Env vars referenced in code but absent from `.env.example`/docs, or the reverse.
- Frontend calls to endpoints that don't exist; backend endpoints nothing calls; mismatched request/response shapes, methods, or paths.
- DB models/schemas without migrations, or migrations that don't match models; queries on nonexistent columns/tables.
- Event emitters with no listeners, listeners for events never emitted.
- Scripts in `package.json`/`Makefile` that point to missing files; Dockerfile/CI referencing nonexistent paths.
- Dependencies imported but missing from the manifest (works only on the author's machine).

## 7. Fake or weak tests
- No assertions; `assert True`; `expect(true).toBe(true)`; tests that only check "doesn't throw".
- Everything under test is mocked, so the test exercises only the mock.
- Skipped/disabled/xfail tests (`skip`, `xit`, `@pytest.mark.skip`, `.only` left in).
- Snapshot tests of trivial output; assertions on values the test itself just set.
- Core logic with zero coverage while trivial getters are tested.
- Test suite that can't run (missing fixtures/config) or is never run in CI.
- Always report the actual result of running the suite, not what the tests claim.

## 8. Security and hygiene
- Secrets committed (API keys, tokens, passwords, private keys, `.env` tracked by git); check git history only if cheap and relevant.
- SQL built by string concatenation; shell commands built from input; `eval`/`exec` on external data; unsanitized HTML output; path traversal in file handling.
- Missing authentication/authorization checks on sensitive routes; trusting client-supplied user IDs or roles.
- Overly permissive CORS, debug mode enabled, verbose error leakage.
- Empty `catch`/`except` blocks and broad catches that swallow errors; `except: pass`.
- Unused, unpinned, or abandoned dependencies; lockfile missing or out of sync with the manifest.
- Insecure defaults (disabled TLS verification, weak hashing, predictable tokens).

## 9. Stack-specific signals
Adapt to what you find in Phase 1.
- **JS/TS**: missing `await`; `any` everywhere; `// @ts-ignore`; `useEffect` with wrong deps; state set but never read; API routes not exported; server code imported into client bundles.
- **Python**: mutable default args; bare `except`; `pass` bodies; missing `__init__`/packaging; blocking calls in async code; requirements out of sync with imports.
- **React/Next/Vue**: components rendering static data; unused hooks/props; forms with no submit handler; buttons with empty `onClick`.
- **Backend/API**: handlers returning canned JSON; no validation; no DB writes behind "save" endpoints; background jobs defined but never scheduled.
- **ML/AI projects**: "model" that is a lookup table or rules; metrics that are hardcoded or random; training loop that never runs; evaluation on training data; API keys/model calls stubbed.
- **CLI tools**: subcommands listed in help but not implemented; flags parsed but ignored.
- **Infra**: Docker/CI/Terraform referencing missing files, wrong ports, or secrets in plaintext.
