#!/usr/bin/env bash
# batna-zopa gate, exercised as a real subprocess.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
HOOKS="$HERE/../batna-zopa/hooks"
pass=0; fail=0
report() { if [ "$2" = "$1" ]; then pass=$((pass+1)); printf 'ok     %-34s %s\n' "$3" "$2"; else fail=$((fail+1)); printf 'FAIL   %-34s want=%s got=%s\n' "$3" "$1" "$2"; fi; }

TARGET=docs/issue-77/proposals/2026-07-28-partnerships-bd.md
RECORD=docs/issue-77/reports/partnerships-bd.md

# run want name content [target_path]
run() {
  target="${4:-$TARGET}"
  td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"
  mkdir -p "$td/$(dirname "$target")"
  printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":%s},"cwd":"%s"}' \
    "$target" "$(python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$3")" "$td" \
    | env CLAUDE_PROJECT_DIR="$td" CLAUDE_ROLE=partnerships-bd /bin/bash "$HOOKS/batna-zopa-gate.sh" >/dev/null 2>&1
  rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  rm -rf "$td"; report "$1" "$got" "$2"
}

BATNA_ONLY='# Proposal
BATNA: if this deal falls through, we continue our existing self-serve
funnel and revisit partnerships in Q4.'
run allow batna-only-pass "$BATNA_ONLY"

NO_BATNA='# Proposal
No walk-away alternative discussed at all, just deal terms.'
run deny no-batna-deny "$NO_BATNA"

BATNA_EMPTY='# Proposal
BATNA: n/a'
run deny batna-empty-deny "$BATNA_EMPTY"

BATNA_COUNTERPART_NO_ZOPA='# Proposal
BATNA: if this deal falls through, we continue our existing self-serve
funnel and revisit partnerships in Q4.
The counterpart has proposed a 15% revenue share.'
run deny counterpart-no-zopa-deny "$BATNA_COUNTERPART_NO_ZOPA"

BATNA_COUNTERPART_ZOPA='# Proposal
BATNA: if this deal falls through, we continue our existing self-serve
funnel and revisit partnerships in Q4.
The counterpart has proposed a 15% revenue share.
ZOPA estimate: our floor is 8%, counterpart ceiling looks like 18%,
overlap likely 10-15%.'
run allow counterpart-zopa-pass "$BATNA_COUNTERPART_ZOPA"

run allow record-path-pass "$BATNA_COUNTERPART_ZOPA" "$RECORD"

# malformed stdin
td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"
printf 'not json' | env CLAUDE_PROJECT_DIR="$td" CLAUDE_ROLE=partnerships-bd /bin/bash "$HOOKS/batna-zopa-gate.sh" >/dev/null 2>&1
rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
rm -rf "$td"; report deny "$got" malformed-stdin-deny

# unrelated path pass-through
td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"
printf '{"tool_name":"Write","tool_input":{"file_path":"src/app.py","content":"x"},"cwd":"%s"}' "$td" \
  | env CLAUDE_PROJECT_DIR="$td" CLAUDE_ROLE=partnerships-bd /bin/bash "$HOOKS/batna-zopa-gate.sh" >/dev/null 2>&1
rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
rm -rf "$td"; report allow "$got" unrelated-path-pass

# kill switch
td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"
mkdir -p "$td/$(dirname "$TARGET")"
printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":%s},"cwd":"%s"}' \
  "$TARGET" "$(python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$NO_BATNA")" "$td" \
  | env CLAUDE_PROJECT_DIR="$td" CLAUDE_ROLE=partnerships-bd BATNA_ZOPA_GATE_OFF=1 /bin/bash "$HOOKS/batna-zopa-gate.sh" >/dev/null 2>&1
rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
rm -rf "$td"; report allow "$got" kill-switch-pass

# wrong role: must not fire
td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"
mkdir -p "$td/$(dirname "$TARGET")"
printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":%s},"cwd":"%s"}' \
  "$TARGET" "$(python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$NO_BATNA")" "$td" \
  | env CLAUDE_PROJECT_DIR="$td" CLAUDE_ROLE=product-discovery /bin/bash "$HOOKS/batna-zopa-gate.sh" >/dev/null 2>&1
rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
rm -rf "$td"; report allow "$got" wrong-role-pass

printf '\n== %d passed, %d failed ==\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
