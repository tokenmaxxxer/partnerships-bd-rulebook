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

# --- mandatory cases (issue-10): Edit replace_all, MultiEdit mixed, ------
# malformed-JSON variants, kill-switch unrecognized value, absolute path,
# Bash-tool write into scope. ------------------------------------------------

DUP_GOOD='# Proposal
Strategic fit: strong ICP overlap with target segment.
Compounding value: this partnership compounds value over time.
Strategic fit: strong ICP overlap with target segment.
Compounding value: this partnership compounds value over time.
No scoring table here at all.'

# Edit replace_all:true deletes BOTH duplicated fit/cv paragraphs -> nothing
# satisfying left -> deny. A first-occurrence-only bug would leave the
# second copy intact and wrongly allow.
td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"
mkdir -p "$td/$(dirname "$TARGET")"
printf '%s' "$DUP_GOOD" > "$td/$TARGET"
old_block='Strategic fit: strong ICP overlap with target segment.
Compounding value: this partnership compounds value over time.'
printf '{"tool_name":"Edit","tool_input":{"file_path":"%s","old_string":%s,"new_string":"","replace_all":true},"cwd":"%s"}' \
  "$TARGET" "$(python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$old_block")" "$td" \
  | env CLAUDE_PROJECT_DIR="$td" CLAUDE_ROLE=partnerships-bd /bin/bash "$HOOKS/strategic-fit-gate.sh" >/dev/null 2>&1
rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
rm -rf "$td"; report deny "$got" edit-replace-all-removes-all-occurrences-deny

# MultiEdit mixed replace_all: the replace_all:true edit strips both fit/cv
# copies (-> would deny alone); the replace_all:false edit only touches an
# unrelated first line. Overall verdict must still be deny, proving the
# replace_all:true edit's effect was not accidentally undone/ignored.
td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"
mkdir -p "$td/$(dirname "$TARGET")"
printf '%s' "$DUP_GOOD" > "$td/$TARGET"
payload="$(python3 -c '
import json
old_block = "Strategic fit: strong ICP overlap with target segment.\nCompounding value: this partnership compounds value over time."
edits = [
    {"old_string": "# Proposal", "new_string": "# Proposal (reviewed)", "replace_all": False},
    {"old_string": old_block, "new_string": "", "replace_all": True},
]
print(json.dumps({"tool_name": "MultiEdit", "tool_input": {"file_path": "'"$TARGET"'", "edits": edits}, "cwd": "'"$td"'"}))
')"
printf '%s' "$payload" | env CLAUDE_PROJECT_DIR="$td" CLAUDE_ROLE=partnerships-bd /bin/bash "$HOOKS/strategic-fit-gate.sh" >/dev/null 2>&1
rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
rm -rf "$td"; report deny "$got" multiedit-mixed-replace-all-deny

# malformed JSON: truncated
td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"
printf '{"tool_name":"Write","tool_inp' | env CLAUDE_PROJECT_DIR="$td" CLAUDE_ROLE=partnerships-bd /bin/bash "$HOOKS/strategic-fit-gate.sh" >/dev/null 2>&1
rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
rm -rf "$td"; report deny "$got" malformed-json-truncated-deny

# malformed JSON: valid JSON but not an object (a bare array)
td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"
printf '[1,2,3]' | env CLAUDE_PROJECT_DIR="$td" CLAUDE_ROLE=partnerships-bd /bin/bash "$HOOKS/strategic-fit-gate.sh" >/dev/null 2>&1
rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
rm -rf "$td"; report deny "$got" malformed-json-non-object-deny

# malformed JSON: empty stdin
td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"
printf '' | env CLAUDE_PROJECT_DIR="$td" CLAUDE_ROLE=partnerships-bd /bin/bash "$HOOKS/strategic-fit-gate.sh" >/dev/null 2>&1
rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
rm -rf "$td"; report deny "$got" malformed-json-empty-stdin-deny

# stderr carries the deny reason (not lost to a stdout JSON blob)
td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"
stderr_out="$(printf '' | env CLAUDE_PROJECT_DIR="$td" CLAUDE_ROLE=partnerships-bd /bin/bash "$HOOKS/strategic-fit-gate.sh" 2>&1 >/dev/null)"
rm -rf "$td"
if printf '%s' "$stderr_out" | grep -q "strategic-fit-gate: refused"; then got=has-reason; else got=no-reason; fi
report has-reason "$got" deny-reason-on-stderr

# kill switch: unrecognized/typo value must stay active (regression for the
# backwards case-statement bug)
td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"
mkdir -p "$td/$(dirname "$TARGET")"
printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":%s},"cwd":"%s"}' \
  "$TARGET" "$(python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$TABLE_NO_LANGUAGE")" "$td" \
  | env CLAUDE_PROJECT_DIR="$td" CLAUDE_ROLE=partnerships-bd STRATEGIC_FIT_GATE_OFF=xyzzy /bin/bash "$HOOKS/strategic-fit-gate.sh" >/dev/null 2>&1
rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
rm -rf "$td"; report deny "$got" kill-switch-unrecognized-value-stays-active

# absolute file_path matching the same scope a relative fixture matches
td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"
mkdir -p "$td/$(dirname "$TARGET")"
printf '{"tool_name":"Write","tool_input":{"file_path":"%s/%s","content":%s},"cwd":"%s"}' \
  "$td" "$TARGET" "$(python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$TABLE_NO_LANGUAGE")" "$td" \
  | env CLAUDE_PROJECT_DIR="$td" CLAUDE_ROLE=partnerships-bd /bin/bash "$HOOKS/strategic-fit-gate.sh" >/dev/null 2>&1
rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
rm -rf "$td"; report deny "$got" absolute-path-deny

# ./-prefixed relative variant, same target
td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"
mkdir -p "$td/$(dirname "$TARGET")"
printf '{"tool_name":"Write","tool_input":{"file_path":"./%s","content":%s},"cwd":"%s"}' \
  "$TARGET" "$(python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$TABLE_NO_LANGUAGE")" "$td" \
  | env CLAUDE_PROJECT_DIR="$td" CLAUDE_ROLE=partnerships-bd /bin/bash "$HOOKS/strategic-fit-gate.sh" >/dev/null 2>&1
rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
rm -rf "$td"; report deny "$got" dot-slash-prefixed-path-deny

# a Bash-tool write reaching this gate's scope is refused the same way a
# Write call would be, instead of silently passing through unreconstructed
td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"
mkdir -p "$td/$(dirname "$TARGET")"
printf '{"tool_name":"Bash","tool_input":{"command":"printf x >> %s"},"cwd":"%s"}' "$TARGET" "$td" \
  | env CLAUDE_PROJECT_DIR="$td" CLAUDE_ROLE=partnerships-bd /bin/bash "$HOOKS/strategic-fit-gate.sh" >/dev/null 2>&1
rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
rm -rf "$td"; report deny "$got" bash-tool-write-into-scope-deny

# missing-core: guarded source must deny, not silently allow (issue-13/issue-75)
td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"
printf '' | env CLAUDE_PROJECT_DIR="$td" CLAUDE_ROLE=partnerships-bd CLAUDE_PLUGIN_ROOT_CORE="$td/no-such-core" /bin/bash "$HOOKS/strategic-fit-gate.sh" >/dev/null 2>&1
rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
rm -rf "$td"; report deny "$got" missing-core-source-guard-deny

printf '\n== %d passed, %d failed ==\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
