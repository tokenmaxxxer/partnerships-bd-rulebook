#!/usr/bin/env bash
# multi-axis-scoring gate, exercised as a real subprocess.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
HOOKS="$HERE/../multi-axis-scoring/hooks"
pass=0; fail=0
report() { if [ "$2" = "$1" ]; then pass=$((pass+1)); printf 'ok     %-34s %s\n' "$3" "$2"; else fail=$((fail+1)); printf 'FAIL   %-34s want=%s got=%s\n' "$3" "$1" "$2"; fi; }

PROPOSAL=docs/issue-77/proposals/2026-07-28-partnerships-bd.md
RECORD=docs/issue-77/reports/partnerships-bd.md

# run want name content target
run() {
  td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"
  mkdir -p "$td/$(dirname "$4")"
  printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":%s},"cwd":"%s"}' \
    "$4" "$(python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$3")" "$td" \
    | env CLAUDE_PROJECT_DIR="$td" CLAUDE_ROLE=partnerships-bd /bin/bash "$HOOKS/multi-axis-scoring-gate.sh" >/dev/null 2>&1
  rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  rm -rf "$td"; report "$1" "$got" "$2"
}

ALL_SIX='# Proposal

| axis | weight | score |
|---|---|---|
| strategic fit / ICP fit | weight: 3 | score: 8 |
| financial health | weight: 2 | score: 7 |
| legal compliance posture | weight: 2 | score: 9 |
| operational capability | weight: 1 | score: 6 |
| cultural fit | weight: 1 | score: 8 |
| compounding-value | weight: 2 | score: 7 |
'
run allow all-six-axes-proposal-pass "$ALL_SIX" "$PROPOSAL"

MISSING_ONE='# Proposal

| axis | weight | score |
|---|---|---|
| strategic fit / ICP fit | weight: 3 | score: 8 |
| financial health | weight: 2 | score: 7 |
| legal compliance posture | weight: 2 | score: 9 |
| operational capability | weight: 1 | score: 6 |
| compounding-value | weight: 2 | score: 7 |
'
run deny missing-one-axis-proposal-deny "$MISSING_ONE" "$PROPOSAL"

NO_WEIGHT_SCORE='# Proposal

We considered strategic/ICP fit, financial health, legal/compliance posture,
operational capability, cultural fit, and compounding-value, but assigned
no numbers to any of them.'
run deny no-weight-score-nearby-deny "$NO_WEIGHT_SCORE" "$PROPOSAL"

run allow all-six-axes-record-pass "$ALL_SIX" "$RECORD"

# malformed stdin
td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"
printf 'not json' | env CLAUDE_PROJECT_DIR="$td" CLAUDE_ROLE=partnerships-bd /bin/bash "$HOOKS/multi-axis-scoring-gate.sh" >/dev/null 2>&1
rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
rm -rf "$td"; report deny "$got" malformed-stdin-deny

# unrelated path pass-through
td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"
printf '{"tool_name":"Write","tool_input":{"file_path":"src/app.py","content":"x"},"cwd":"%s"}' "$td" \
  | env CLAUDE_PROJECT_DIR="$td" CLAUDE_ROLE=partnerships-bd /bin/bash "$HOOKS/multi-axis-scoring-gate.sh" >/dev/null 2>&1
rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
rm -rf "$td"; report allow "$got" unrelated-path-pass

# kill switch
td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"
mkdir -p "$td/$(dirname "$PROPOSAL")"
printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":%s},"cwd":"%s"}' \
  "$PROPOSAL" "$(python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$MISSING_ONE")" "$td" \
  | env CLAUDE_PROJECT_DIR="$td" CLAUDE_ROLE=partnerships-bd MULTI_AXIS_SCORING_GATE_OFF=1 /bin/bash "$HOOKS/multi-axis-scoring-gate.sh" >/dev/null 2>&1
rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
rm -rf "$td"; report allow "$got" kill-switch-pass

# wrong role pass-through (matching path, content would otherwise deny)
td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"
mkdir -p "$td/$(dirname "$PROPOSAL")"
printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":%s},"cwd":"%s"}' \
  "$PROPOSAL" "$(python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$MISSING_ONE")" "$td" \
  | env CLAUDE_PROJECT_DIR="$td" CLAUDE_ROLE=pricing /bin/bash "$HOOKS/multi-axis-scoring-gate.sh" >/dev/null 2>&1
rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
rm -rf "$td"; report allow "$got" wrong-role-pass-through

printf '\n== %d passed, %d failed ==\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
