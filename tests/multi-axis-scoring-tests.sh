#!/usr/bin/env bash
# multi-axis-scoring gate, exercised as a real subprocess.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
HOOKS="$HERE/../multi-axis-scoring/hooks"
. "$HERE/lib/resolve-core.sh"
# Convention: docs/specs/test-env-resolution.md (on-the-record issue #551).
CORE_ROOT="$(resolve_core "$HERE/../../core" "$HERE/../../tokenmaxxxer-core/core")" || exit 75
export CLAUDE_PLUGIN_ROOT_CORE="$CORE_ROOT"
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

# --- mandatory cases (issue-10): Edit replace_all, MultiEdit mixed, ------
# malformed-JSON variants, kill-switch unrecognized value, absolute path,
# Bash-tool write into scope. ------------------------------------------------

TWO_BLANKS='# Proposal

| axis | weight | score |
|---|---|---|
| strategic fit / ICP fit | PLACEHOLDER | PLACEHOLDER |
| financial health | weight: 2 | score: 7 |
| legal compliance posture | weight: 2 | score: 9 |
| operational capability | weight: 1 | score: 6 |
| cultural fit | weight: 1 | score: 8 |
| compounding-value | PLACEHOLDER | PLACEHOLDER |
'

# Edit replace_all:true fills BOTH blank axis rows -> all six axes covered
# -> allow. A first-occurrence-only bug would leave the last row's
# PLACEHOLDER cells untouched -> compounding-value stays missing -> deny.
td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"
mkdir -p "$td/$(dirname "$PROPOSAL")"
printf '%s' "$TWO_BLANKS" > "$td/$PROPOSAL"
printf '{"tool_name":"Edit","tool_input":{"file_path":"%s","old_string":"PLACEHOLDER","new_string":"weight: 3","replace_all":true},"cwd":"%s"}' \
  "$PROPOSAL" "$td" \
  | env CLAUDE_PROJECT_DIR="$td" CLAUDE_ROLE=partnerships-bd /bin/bash "$HOOKS/multi-axis-scoring-gate.sh" >/dev/null 2>&1
rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
rm -rf "$td"; report allow "$got" edit-replace-all-fills-all-blanks-allow

# The same Edit WITHOUT replace_all (defaults to first-occurrence-only)
# must leave the compounding-value row incomplete -> deny. This is the
# direct regression check for "replace_all never read."
td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"
mkdir -p "$td/$(dirname "$PROPOSAL")"
printf '%s' "$TWO_BLANKS" > "$td/$PROPOSAL"
printf '{"tool_name":"Edit","tool_input":{"file_path":"%s","old_string":"PLACEHOLDER","new_string":"weight: 3"},"cwd":"%s"}' \
  "$PROPOSAL" "$td" \
  | env CLAUDE_PROJECT_DIR="$td" CLAUDE_ROLE=partnerships-bd /bin/bash "$HOOKS/multi-axis-scoring-gate.sh" >/dev/null 2>&1
rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
rm -rf "$td"; report deny "$got" edit-without-replace-all-first-occurrence-only-deny

# MultiEdit mixed: two edits in one call, each with its own replace_all
# value (false for the strategic-fit row's single-occurrence line, true for
# the compounding-value row's), both must be applied independently for the
# result to pass all six axes.
td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"
mkdir -p "$td/$(dirname "$PROPOSAL")"
printf '%s' "$TWO_BLANKS" > "$td/$PROPOSAL"
payload="$(python3 -c '
import json
edits = [
    {"old_string": "| strategic fit / ICP fit | PLACEHOLDER | PLACEHOLDER |",
     "new_string": "| strategic fit / ICP fit | weight: 3 | score: 8 |",
     "replace_all": False},
    {"old_string": "| compounding-value | PLACEHOLDER | PLACEHOLDER |",
     "new_string": "| compounding-value | weight: 2 | score: 7 |",
     "replace_all": True},
]
print(json.dumps({"tool_name": "MultiEdit", "tool_input": {"file_path": "'"$PROPOSAL"'", "edits": edits}, "cwd": "'"$td"'"}))
')"
printf '%s' "$payload" | env CLAUDE_PROJECT_DIR="$td" CLAUDE_ROLE=partnerships-bd /bin/bash "$HOOKS/multi-axis-scoring-gate.sh" >/dev/null 2>&1
rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
rm -rf "$td"; report allow "$got" multiedit-mixed-replace-all-allow

# malformed JSON: truncated
td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"
printf '{"tool_name":"Write","tool_inp' | env CLAUDE_PROJECT_DIR="$td" CLAUDE_ROLE=partnerships-bd /bin/bash "$HOOKS/multi-axis-scoring-gate.sh" >/dev/null 2>&1
rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
rm -rf "$td"; report deny "$got" malformed-json-truncated-deny

# malformed JSON: valid JSON but not an object
td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"
printf '[1,2,3]' | env CLAUDE_PROJECT_DIR="$td" CLAUDE_ROLE=partnerships-bd /bin/bash "$HOOKS/multi-axis-scoring-gate.sh" >/dev/null 2>&1
rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
rm -rf "$td"; report deny "$got" malformed-json-non-object-deny

# malformed JSON: empty stdin
td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"
printf '' | env CLAUDE_PROJECT_DIR="$td" CLAUDE_ROLE=partnerships-bd /bin/bash "$HOOKS/multi-axis-scoring-gate.sh" >/dev/null 2>&1
rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
rm -rf "$td"; report deny "$got" malformed-json-empty-stdin-deny

# kill switch: unrecognized/typo value must stay active
td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"
mkdir -p "$td/$(dirname "$PROPOSAL")"
printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":%s},"cwd":"%s"}' \
  "$PROPOSAL" "$(python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$MISSING_ONE")" "$td" \
  | env CLAUDE_PROJECT_DIR="$td" CLAUDE_ROLE=partnerships-bd MULTI_AXIS_SCORING_GATE_OFF=xyzzy /bin/bash "$HOOKS/multi-axis-scoring-gate.sh" >/dev/null 2>&1
rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
rm -rf "$td"; report deny "$got" kill-switch-unrecognized-value-stays-active

# absolute file_path matching the same scope a relative fixture matches
td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"
mkdir -p "$td/$(dirname "$PROPOSAL")"
printf '{"tool_name":"Write","tool_input":{"file_path":"%s/%s","content":%s},"cwd":"%s"}' \
  "$td" "$PROPOSAL" "$(python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$MISSING_ONE")" "$td" \
  | env CLAUDE_PROJECT_DIR="$td" CLAUDE_ROLE=partnerships-bd /bin/bash "$HOOKS/multi-axis-scoring-gate.sh" >/dev/null 2>&1
rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
rm -rf "$td"; report deny "$got" absolute-path-deny

# ./-prefixed relative variant
td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"
mkdir -p "$td/$(dirname "$PROPOSAL")"
printf '{"tool_name":"Write","tool_input":{"file_path":"./%s","content":%s},"cwd":"%s"}' \
  "$PROPOSAL" "$(python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$MISSING_ONE")" "$td" \
  | env CLAUDE_PROJECT_DIR="$td" CLAUDE_ROLE=partnerships-bd /bin/bash "$HOOKS/multi-axis-scoring-gate.sh" >/dev/null 2>&1
rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
rm -rf "$td"; report deny "$got" dot-slash-prefixed-path-deny

# a Bash-tool write reaching this gate's scope is refused the same way
td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"
mkdir -p "$td/$(dirname "$PROPOSAL")"
printf '{"tool_name":"Bash","tool_input":{"command":"printf x >> %s"},"cwd":"%s"}' "$PROPOSAL" "$td" \
  | env CLAUDE_PROJECT_DIR="$td" CLAUDE_ROLE=partnerships-bd /bin/bash "$HOOKS/multi-axis-scoring-gate.sh" >/dev/null 2>&1
rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
rm -rf "$td"; report deny "$got" bash-tool-write-into-scope-deny

# missing-core: guarded source must deny, not silently allow (issue-13/issue-75)
td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"
printf '' | env CLAUDE_PROJECT_DIR="$td" CLAUDE_ROLE=partnerships-bd CLAUDE_PLUGIN_ROOT_CORE="$td/no-such-core" /bin/bash "$HOOKS/multi-axis-scoring-gate.sh" >/dev/null 2>&1
rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
rm -rf "$td"; report deny "$got" missing-core-source-guard-deny

printf '\n== %d passed, %d failed ==\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
