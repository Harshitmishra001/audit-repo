# audit-repo

A skill for Claude that audits a codebase like a skeptical senior reviewer. It checks what a project *claims* against what the code *actually does*.

It looks for:
- Bugs and broken logic
- Incomplete code (TODOs, stubs, empty functions, dead files)
- Fake placeholders and mock data posing as real
- Hardcoded or faked results
- Broken wiring (unregistered routes, missing env vars, mismatched endpoints)
- Fake or weak tests
- Security and hygiene problems

It also grades every feature in your README as **REAL / PARTIAL / FAKE / MISSING / UNVERIFIED**, with `file:line` evidence, and ends with a prioritized fix plan. It is read-only: it audits, it doesn't edit your code.

## Install

### Claude Code (all your projects)
```bash
git clone https://github.com/YOUR-USERNAME/audit-repo.git
mkdir -p ~/.claude/skills
cp -r audit-repo/audit-repo ~/.claude/skills/
```

### Claude Code (one project only)
```bash
mkdir -p .claude/skills
cp -r audit-repo/audit-repo .claude/skills/
```

### Claude.ai / Claude app
Download `audit-repo.skill` from the [latest release](../../releases/latest) (or from this repo), open it in Claude, and click **Save skill**.

## Use

In Claude Code, from your project folder:

```
/audit-repo
```

or just say: *"Audit this repo and write the report to AUDIT.md"*.

Tip: run it in plan mode (`claude --permission-mode plan`) as an extra guarantee that nothing gets edited.

## What's inside

```
audit-repo/
├── SKILL.md                      # workflow and rules
├── references/
│   ├── checklist.md              # detailed signals per problem category
│   └── report-template.md        # report structure
└── scripts/
    └── sweep.sh                  # fast read-only grep sweep for leads
```

## License

MIT. See [LICENSE](LICENSE).
