#!/usr/bin/env bash
# strategic-fit-gate gate, exercised as a real subprocess.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
HOOKS="$HERE/../strategic-fit-gate/hooks"
pass=0; fail=0
report() { if [ "$2" = "$1" ]; then pass=$((pass+1)); printf 'ok     %-34s %s\n' "$3" "$2"; else fail=$((fail+1)); printf 'FAIL   %-34s want=%s got=%s\n' "$3" "$1" "$2"; fi; }

TARGET=docs/issue-77/proposals/2026-07-28-partnerships-bd.md

# run want name content
run() {
  td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"
  mkdir -p "$td/$(dirname "$TARGET")"
  printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":%s},"cwd":"%s"}' \
    "$TARGET" "$(python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$3")" "$td" \
    | env CLAUDE_PROJECT_DIR="$td" CLAUDE_ROLE=partnerships-bd /bin/bash "$HOOKS/strategic-fit-gate.sh" >/dev/null 2>&1
  rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  rm -rf "$td"; report "$1" "$got" "$2"
}

GOOD_NO_TABLE='# Proposal
Strategic fit: strong ICP overlap with target segment.
Compounding value: this partnership compounds value over time.
No scoring table here at all.'
run allow no-table-with-fit-cv "$GOOD_NO_TABLE"

TABLE_NO_LANGUAGE='# Proposal
| Criteria | Score |
| --- | --- |
| Financial | 8 |
No fit or value language anywhere.'
run deny table-no-language "$TABLE_NO_LANGUAGE"

LANGUAGE_AFTER_TABLE='# Proposal
| Criteria | Score |
| --- | --- |
| Financial | 8 |
Strategic fit: ICP overlap noted here.
Compounding value: yes, it compounds value.'
run deny language-after-table "$LANGUAGE_AFTER_TABLE"

LANGUAGE_BEFORE_TABLE='# Proposal
Strategic fit: strong ICP overlap with target segment.
Compounding value: this partnership compounds value over time.

| Criteria | Score |
| --- | --- |
| Financial | 8 |'
run allow language-before-table "$LANGUAGE_BEFORE_TABLE"

# malformed stdin
td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"
printf 'not json' | env CLAUDE_PROJECT_DIR="$td" CLAUDE_ROLE=partnerships-bd /bin/bash "$HOOKS/strategic-fit-gate.sh" >/dev/null 2>&1
rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
rm -rf "$td"; report deny "$got" malformed-stdin-deny

# unrelated path pass-through
td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"
printf '{"tool_name":"Write","tool_input":{"file_path":"src/app.py","content":"x"},"cwd":"%s"}' "$td" \
  | env CLAUDE_PROJECT_DIR="$td" CLAUDE_ROLE=partnerships-bd /bin/bash "$HOOKS/strategic-fit-gate.sh" >/dev/null 2>&1
rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
rm -rf "$td"; report allow "$got" unrelated-path-pass

# kill switch
td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"
mkdir -p "$td/$(dirname "$TARGET")"
printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":%s},"cwd":"%s"}' \
  "$TARGET" "$(python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$TABLE_NO_LANGUAGE")" "$td" \
  | env CLAUDE_PROJECT_DIR="$td" CLAUDE_ROLE=partnerships-bd STRATEGIC_FIT_GATE_OFF=1 /bin/bash "$HOOKS/strategic-fit-gate.sh" >/dev/null 2>&1
rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
rm -rf "$td"; report allow "$got" kill-switch-pass

# cross-role: gate must not fire, pass through
td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"
mkdir -p "$td/$(dirname "$TARGET")"
printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":%s},"cwd":"%s"}' \
  "$TARGET" "$(python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$TABLE_NO_LANGUAGE")" "$td" \
  | env CLAUDE_PROJECT_DIR="$td" CLAUDE_ROLE=pricing /bin/bash "$HOOKS/strategic-fit-gate.sh" >/dev/null 2>&1
rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
rm -rf "$td"; report allow "$got" cross-role-pass-through

# phase-2 record path: out of scope, pass through
td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"
RECORD_TARGET=docs/issue-77/reports/partnerships-bd.md
mkdir -p "$td/$(dirname "$RECORD_TARGET")"
printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":%s},"cwd":"%s"}' \
  "$RECORD_TARGET" "$(python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$TABLE_NO_LANGUAGE")" "$td" \
  | env CLAUDE_PROJECT_DIR="$td" CLAUDE_ROLE=partnerships-bd /bin/bash "$HOOKS/strategic-fit-gate.sh" >/dev/null 2>&1
rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
rm -rf "$td"; report allow "$got" phase2-record-pass-through

printf '\n== %d passed, %d failed ==\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
