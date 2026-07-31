#!/usr/bin/env bash
# evidence-discipline gate, exercised as a real subprocess.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
HOOKS="$HERE/../evidence-discipline/hooks"
pass=0; fail=0
report() { if [ "$2" = "$1" ]; then pass=$((pass+1)); printf 'ok     %-34s %s\n' "$3" "$2"; else fail=$((fail+1)); printf 'FAIL   %-34s want=%s got=%s\n' "$3" "$1" "$2"; fi; }

TARGET=docs/issue-77/proposals/2026-07-28-partnerships-bd.md
RECORD=docs/issue-77/reports/partnerships-bd.md

# run want name content [role] [target]
run() {
  local want="$1" name="$2" content="$3" role="${4:-partnerships-bd}" target="${5:-$TARGET}"
  td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"
  mkdir -p "$td/$(dirname "$target")"
  printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":%s},"cwd":"%s"}' \
    "$target" "$(python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$content")" "$td" \
    | env CLAUDE_PROJECT_DIR="$td" CLAUDE_ROLE="$role" /bin/bash "$HOOKS/evidence-discipline-gate.sh" >/dev/null 2>&1
  rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  rm -rf "$td"; report "$want" "$got" "$name"
}

GOOD='# Proposal
Stage: binding-terms-ready
Source: adoption doc docs/issue-1/proposals/rulebook-maturation.md — 2026-07-20'
run allow stage-and-source-pass "$GOOD"

NO_STAGE='# Proposal
Source: adoption doc docs/issue-1/proposals/rulebook-maturation.md — 2026-07-20'
run deny no-stage-deny "$NO_STAGE"

NO_CITATION='# Proposal
Stage: non-binding
No sources listed anywhere in this document.'
run deny no-citation-deny "$NO_CITATION"

MD_LINK='# Proposal
Stage: non-binding
See [adoption doc](docs/issue-1/proposals/rulebook-maturation.md) for framework basis.'
run allow markdown-link-citation-pass "$MD_LINK"

# malformed stdin
td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"
printf 'not json' | env CLAUDE_PROJECT_DIR="$td" CLAUDE_ROLE=partnerships-bd /bin/bash "$HOOKS/evidence-discipline-gate.sh" >/dev/null 2>&1
rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
rm -rf "$td"; report deny "$got" malformed-stdin-deny

run allow unrelated-path-pass "$NO_CITATION" partnerships-bd src/app.py

# kill switch
td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"
mkdir -p "$td/$(dirname "$TARGET")"
printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":%s},"cwd":"%s"}' \
  "$TARGET" "$(python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$NO_CITATION")" "$td" \
  | env CLAUDE_PROJECT_DIR="$td" CLAUDE_ROLE=partnerships-bd EVIDENCE_DISCIPLINE_GATE_OFF=1 /bin/bash "$HOOKS/evidence-discipline-gate.sh" >/dev/null 2>&1
rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
rm -rf "$td"; report allow "$got" kill-switch-pass

run allow phase2-record-passthrough "$NO_CITATION" partnerships-bd "$RECORD"

run allow wrong-role-passthrough "$NO_CITATION" other-role "$TARGET"

printf '\n== %d passed, %d failed ==\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
