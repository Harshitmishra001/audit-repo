#!/usr/bin/env bash
# Fast first-pass sweep for audit-repo. Prints suspicious patterns with file:line.
# This is a LEAD GENERATOR: every hit must be read in context before it becomes a finding.
# Read-only. Usage: sweep.sh [repo-root]

ROOT="${1:-.}"
cd "$ROOT" || { echo "cannot cd to $ROOT" >&2; exit 1; }

EXCLUDES=(--exclude-dir=node_modules --exclude-dir=.git --exclude-dir=venv --exclude-dir=.venv
          --exclude-dir=dist --exclude-dir=build --exclude-dir=target --exclude-dir=__pycache__
          --exclude-dir=.next --exclude-dir=vendor --exclude-dir=coverage
          --exclude=package-lock.json --exclude=yarn.lock --exclude=pnpm-lock.yaml
          --exclude=poetry.lock --exclude=Cargo.lock --exclude=*.min.js --exclude=*.map)

section() { printf '\n===== %s =====\n' "$1"; }
sweep() { # title, extended-regex
  section "$1"
  grep -rnIE "${EXCLUDES[@]}" -- "$2" . 2>/dev/null | head -n "${LIMIT:-60}"
}

echo "Sweep of: $(pwd)"
echo "(first ${LIMIT:-60} hits per category; set LIMIT=N to change)"

section "FILE COUNT BY EXTENSION (top 15)"
find . -type f -not -path './.git/*' -not -path '*/node_modules/*' -not -path '*/venv/*' -not -path '*/.venv/*' \
  | sed -n 's/.*\.\([A-Za-z0-9]*\)$/\1/p' | sort | uniq -c | sort -rn | head -15

section "EMPTY OR TINY SOURCE FILES (<= 3 lines)"
find . -type f \( -name '*.py' -o -name '*.js' -o -name '*.jsx' -o -name '*.ts' -o -name '*.tsx' \
  -o -name '*.go' -o -name '*.rs' -o -name '*.java' -o -name '*.rb' -o -name '*.php' -o -name '*.c' -o -name '*.cpp' \) \
  -not -path './.git/*' -not -path '*/node_modules/*' -not -path '*/venv/*' -not -path '*/.venv/*' \
  -not -path '*/dist/*' -not -path '*/build/*' 2>/dev/null \
  | while read -r f; do n=$(wc -l < "$f"); [ "$n" -le 3 ] && echo "$f ($n lines)"; done | head -40

sweep "TODO / FIXME / HACK MARKERS" '(TODO|FIXME|HACK|XXX|WIP)\b'
sweep "'NOT IMPLEMENTED' / STUBS" 'NotImplemented|not implemented|unimplemented!|todo!\(|stub|for now|temporary|temp fix'
sweep "EMPTY BODIES (python pass / ellipsis)" '^\s*(pass|\.\.\.)\s*$'
sweep "PLACEHOLDER TEXT AND DATA" 'lorem ipsum|dummy|placeholder|john doe|jane doe|test@test|@example\.com|example\.com|your[-_ ]?(api[-_ ]?)?(key|token)|changeme|xxxx+|sample[_ ]?data|fake[_ ]?data'
sweep "MOCK / FAKE NAMES IN SOURCE" '\b(mock|fake|stub)[A-Z_a-z]*\b'
sweep "FAKE DELAYS / SIMULATED WORK" 'setTimeout\(|time\.sleep\(|asyncio\.sleep\(|await (delay|sleep)\(|Thread\.sleep|simulate'
sweep "RANDOM DATA (check if posing as real results)" 'Math\.random\(|random\.(random|randint|choice|uniform)|rand\(\)'
sweep "HARDCODED URLS / LOCALHOST / PORTS" 'https?://(localhost|127\.0\.0\.1|0\.0\.0\.0)|localhost:[0-9]+'
sweep "HARDCODED ABSOLUTE PATHS" '(/Users/[A-Za-z0-9_.-]+|/home/[A-Za-z0-9_.-]+|C:\\\\Users)'
sweep "POSSIBLE COMMITTED SECRETS" '(api[_-]?key|secret|passwd|password|token|private[_-]?key)["'"'"' ]*[:=]["'"'"' ]*[A-Za-z0-9_\-]{12,}|sk-[A-Za-z0-9]{20,}|AKIA[0-9A-Z]{16}|BEGIN (RSA |EC )?PRIVATE KEY'
sweep "SWALLOWED ERRORS (empty catch / bare except)" 'catch\s*(\([^)]*\))?\s*\{\s*\}|except\s*(Exception)?\s*:\s*pass|except:\s*$'
sweep "SKIPPED / FOCUSED TESTS" '\b(xit|xdescribe|it\.skip|test\.skip|describe\.skip|it\.only|test\.only|describe\.only)\b|@pytest\.mark\.(skip|xfail)|@unittest\.skip|t\.Skip\('
sweep "TRIVIAL ASSERTIONS" 'assert True|expect\(true\)\.toBe\(true\)|assertTrue\(true\)'
sweep "TYPE/LINT SUPPRESSIONS" '@ts-ignore|@ts-nocheck|# type: ignore|# noqa|eslint-disable|# pylint: disable'
sweep "SUSPICIOUS CONSTANT RETURNS" 'return (true|false|null|None|[0-9]+(\.[0-9]+)?|""|'"''"'|\[\]|\{\}|"ok"|"success")\s*;?\s*$'

section "ENV VARS REFERENCED vs DEFINED"
echo "-- referenced in code:"
grep -rnIoE "${EXCLUDES[@]}" 'process\.env\.[A-Z0-9_]+|os\.environ(\.get)?\(?\[?["'"'"'][A-Z0-9_]+|os\.getenv\(["'"'"'][A-Z0-9_]+|import\.meta\.env\.[A-Z0-9_]+' . 2>/dev/null \
  | sed -E 's/.*(process\.env\.|import\.meta\.env\.)//; s/.*["'"'"']([A-Z0-9_]+)$/\1/' | sort -u | head -50
echo "-- defined in .env*/example files:"
find . -maxdepth 3 -name '.env*' -not -path '*/node_modules/*' -exec sh -c 'echo "[$1]"; sed -E "s/=.*//" "$1" | grep -v "^#" | grep -v "^$"' _ {} \; 2>/dev/null | head -50

echo
echo "Sweep done. Treat every hit as a lead; read it in context before reporting."
