#!/usr/bin/env bash
# term-sheet-structure gate, exercised as a real subprocess.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
HOOKS="$HERE/../term-sheet-structure/hooks"
pass=0; fail=0
report() { if [ "$2" = "$1" ]; then pass=$((pass+1)); printf 'ok     %-34s %s\n' "$3" "$2"; else fail=$((fail+1)); printf 'FAIL   %-34s want=%s got=%s\n' "$3" "$1" "$2"; fi; }

TARGET=docs/issue-77/reports/partnerships-bd.md

# run want name content
run() {
  td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"
  mkdir -p "$td/$(dirname "$TARGET")"
  printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":%s},"cwd":"%s"}' \
    "$TARGET" "$(python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$3")" "$td" \
    | env CLAUDE_PROJECT_DIR="$td" CLAUDE_ROLE=partnerships-bd /bin/bash "$HOOKS/term-sheet-structure-gate.sh" >/dev/null 2>&1
  rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  rm -rf "$td"; report "$1" "$got" "$2"
}

FULL='# term-sheet-outline

## Purpose
Establish the joint venture partnership objective.

## Roles & Responsibilities
Each party contributes engineering resources.

## Terms
Profit-sharing terms are split 50/50.

## Governance
Quarterly steering committee reviews performance.

## KPIs
Revenue growth and retention are tracked monthly.

## Dispute Resolution
Disputes go to mediation first, then arbitration.

## Exit/Termination
Either party may terminate with 90 days notice.'
run allow full-term-sheet-pass "$FULL"

NO_EXIT='# term-sheet-outline

## Purpose
Establish the joint venture partnership objective.

## Roles & Responsibilities
Each party contributes engineering resources.

## Terms
Profit-sharing terms are split 50/50.

## Governance
Quarterly steering committee reviews performance.

## KPIs
Revenue growth and retention are tracked monthly.

## Dispute Resolution
Disputes go to mediation first, then arbitration.'
run deny missing-exit-deny "$NO_EXIT"

NO_PURPOSE_NO_DISPUTE='# term-sheet-outline

## Roles & Responsibilities
Each party contributes engineering resources.

## Terms
Profit-sharing terms are split 50/50.

## Governance
Quarterly steering committee reviews performance.

## KPIs
Revenue growth and retention are tracked monthly.

## Exit/Termination
Either party may terminate with 90 days notice.'
run deny missing-multiple-deny "$NO_PURPOSE_NO_DISPUTE"

MERGED_GOV_KPI='# term-sheet-outline

## Purpose
Establish the joint venture partnership objective.

## Roles & Responsibilities
Each party contributes engineering resources.

## Terms
Profit-sharing terms are split 50/50.

## Governance/KPIs
Quarterly review of steering committee and revenue growth metrics.

## Dispute Resolution
Disputes go to mediation first, then arbitration.

## Exit/Termination
Either party may terminate with 90 days notice.'
run deny governance-kpi-merged-deny "$MERGED_GOV_KPI"

OUT_OF_SCOPE='# Partnerships-BD Record

Some unrelated prose about the deal context and background,
with no term sheet content whatsoever.'
run allow out-of-scope-pass "$OUT_OF_SCOPE"

# malformed stdin
td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"
printf 'not json' | env CLAUDE_PROJECT_DIR="$td" CLAUDE_ROLE=partnerships-bd /bin/bash "$HOOKS/term-sheet-structure-gate.sh" >/dev/null 2>&1
rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
rm -rf "$td"; report deny "$got" malformed-stdin-deny

# unrelated path pass-through
td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"
printf '{"tool_name":"Write","tool_input":{"file_path":"src/app.py","content":"x"},"cwd":"%s"}' "$td" \
  | env CLAUDE_PROJECT_DIR="$td" CLAUDE_ROLE=partnerships-bd /bin/bash "$HOOKS/term-sheet-structure-gate.sh" >/dev/null 2>&1
rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
rm -rf "$td"; report allow "$got" unrelated-path-pass

# kill switch
td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"
mkdir -p "$td/$(dirname "$TARGET")"
printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":%s},"cwd":"%s"}' \
  "$TARGET" "$(python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$NO_EXIT")" "$td" \
  | env CLAUDE_PROJECT_DIR="$td" CLAUDE_ROLE=partnerships-bd TERM_SHEET_STRUCTURE_GATE_OFF=1 /bin/bash "$HOOKS/term-sheet-structure-gate.sh" >/dev/null 2>&1
rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
rm -rf "$td"; report allow "$got" kill-switch-pass

# phase-1 proposal path (out of scope, must not fire)
td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"
mkdir -p "$td/docs/issue-77/proposals"
printf '{"tool_name":"Write","tool_input":{"file_path":"docs/issue-77/proposals/2026-07-28-partnerships-bd.md","content":%s},"cwd":"%s"}' \
  "$(python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$NO_EXIT")" "$td" \
  | env CLAUDE_PROJECT_DIR="$td" CLAUDE_ROLE=partnerships-bd /bin/bash "$HOOKS/term-sheet-structure-gate.sh" >/dev/null 2>&1
rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
rm -rf "$td"; report allow "$got" phase1-proposal-path-pass

# wrong CLAUDE_ROLE (must not fire)
td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"
mkdir -p "$td/$(dirname "$TARGET")"
printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":%s},"cwd":"%s"}' \
  "$TARGET" "$(python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$NO_EXIT")" "$td" \
  | env CLAUDE_PROJECT_DIR="$td" CLAUDE_ROLE=product-discovery /bin/bash "$HOOKS/term-sheet-structure-gate.sh" >/dev/null 2>&1
rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
rm -rf "$td"; report allow "$got" wrong-role-pass

# --- mandatory cases (issue-10): Edit replace_all, MultiEdit mixed, ------
# malformed-JSON variants, kill-switch unrecognized value, absolute path,
# Bash-tool write into scope. ------------------------------------------------

EXIT_BLOCK='## Exit/Termination
Either party may terminate with 90 days notice.'

DUP_FULL="$FULL

$EXIT_BLOCK

END_MARKER"

# Edit replace_all:true deletes BOTH copies of the exit/termination section
# -> missing exit clause -> deny. A first-occurrence-only bug would leave
# the duplicated copy intact and wrongly allow.
td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"
mkdir -p "$td/$(dirname "$TARGET")"
printf '%s' "$DUP_FULL" > "$td/$TARGET"
printf '{"tool_name":"Edit","tool_input":{"file_path":"%s","old_string":%s,"new_string":"","replace_all":true},"cwd":"%s"}' \
  "$TARGET" "$(python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$EXIT_BLOCK")" "$td" \
  | env CLAUDE_PROJECT_DIR="$td" CLAUDE_ROLE=partnerships-bd /bin/bash "$HOOKS/term-sheet-structure-gate.sh" >/dev/null 2>&1
rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
rm -rf "$td"; report deny "$got" edit-replace-all-removes-all-occurrences-deny

# MultiEdit mixed: a replace_all:false edit touches an unrelated marker; a
# replace_all:true edit strips both copies of the exit/termination block.
td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"
mkdir -p "$td/$(dirname "$TARGET")"
printf '%s' "$DUP_FULL" > "$td/$TARGET"
payload="$(BLOCK="$EXIT_BLOCK" TARGET_PATH="$TARGET" CWD_PATH="$td" python3 -c '
import json, os
edits = [
    {"old_string": "END_MARKER", "new_string": "END_MARKER (checked)", "replace_all": False},
    {"old_string": os.environ["BLOCK"], "new_string": "", "replace_all": True},
]
print(json.dumps({"tool_name": "MultiEdit", "tool_input": {"file_path": os.environ["TARGET_PATH"], "edits": edits}, "cwd": os.environ["CWD_PATH"]}))
')"
printf '%s' "$payload" | env CLAUDE_PROJECT_DIR="$td" CLAUDE_ROLE=partnerships-bd /bin/bash "$HOOKS/term-sheet-structure-gate.sh" >/dev/null 2>&1
rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
rm -rf "$td"; report deny "$got" multiedit-mixed-replace-all-deny

# malformed JSON: truncated
td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"
printf '{"tool_name":"Write","tool_inp' | env CLAUDE_PROJECT_DIR="$td" CLAUDE_ROLE=partnerships-bd /bin/bash "$HOOKS/term-sheet-structure-gate.sh" >/dev/null 2>&1
rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
rm -rf "$td"; report deny "$got" malformed-json-truncated-deny

# malformed JSON: valid JSON but not an object
td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"
printf '[1,2,3]' | env CLAUDE_PROJECT_DIR="$td" CLAUDE_ROLE=partnerships-bd /bin/bash "$HOOKS/term-sheet-structure-gate.sh" >/dev/null 2>&1
rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
rm -rf "$td"; report deny "$got" malformed-json-non-object-deny

# malformed JSON: empty stdin
td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"
printf '' | env CLAUDE_PROJECT_DIR="$td" CLAUDE_ROLE=partnerships-bd /bin/bash "$HOOKS/term-sheet-structure-gate.sh" >/dev/null 2>&1
rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
rm -rf "$td"; report deny "$got" malformed-json-empty-stdin-deny

# kill switch: unrecognized/typo value must stay active
td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"
mkdir -p "$td/$(dirname "$TARGET")"
printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":%s},"cwd":"%s"}' \
  "$TARGET" "$(python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$NO_EXIT")" "$td" \
  | env CLAUDE_PROJECT_DIR="$td" CLAUDE_ROLE=partnerships-bd TERM_SHEET_STRUCTURE_GATE_OFF=xyzzy /bin/bash "$HOOKS/term-sheet-structure-gate.sh" >/dev/null 2>&1
rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
rm -rf "$td"; report deny "$got" kill-switch-unrecognized-value-stays-active

# absolute file_path matching the same scope a relative fixture matches
td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"
mkdir -p "$td/$(dirname "$TARGET")"
printf '{"tool_name":"Write","tool_input":{"file_path":"%s/%s","content":%s},"cwd":"%s"}' \
  "$td" "$TARGET" "$(python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$NO_EXIT")" "$td" \
  | env CLAUDE_PROJECT_DIR="$td" CLAUDE_ROLE=partnerships-bd /bin/bash "$HOOKS/term-sheet-structure-gate.sh" >/dev/null 2>&1
rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
rm -rf "$td"; report deny "$got" absolute-path-deny

# ./-prefixed relative variant
td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"
mkdir -p "$td/$(dirname "$TARGET")"
printf '{"tool_name":"Write","tool_input":{"file_path":"./%s","content":%s},"cwd":"%s"}' \
  "$TARGET" "$(python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$NO_EXIT")" "$td" \
  | env CLAUDE_PROJECT_DIR="$td" CLAUDE_ROLE=partnerships-bd /bin/bash "$HOOKS/term-sheet-structure-gate.sh" >/dev/null 2>&1
rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
rm -rf "$td"; report deny "$got" dot-slash-prefixed-path-deny

# a Bash-tool write reaching this gate's scope is refused the same way
td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"
mkdir -p "$td/$(dirname "$TARGET")"
printf '{"tool_name":"Bash","tool_input":{"command":"printf x >> %s"},"cwd":"%s"}' "$TARGET" "$td" \
  | env CLAUDE_PROJECT_DIR="$td" CLAUDE_ROLE=partnerships-bd /bin/bash "$HOOKS/term-sheet-structure-gate.sh" >/dev/null 2>&1
rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
rm -rf "$td"; report deny "$got" bash-tool-write-into-scope-deny

# missing-core: guarded source must deny, not silently allow (issue-13/issue-75)
td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"
printf '' | env CLAUDE_PROJECT_DIR="$td" CLAUDE_ROLE=partnerships-bd CLAUDE_PLUGIN_ROOT_CORE="$td/no-such-core" /bin/bash "$HOOKS/term-sheet-structure-gate.sh" >/dev/null 2>&1
rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
rm -rf "$td"; report deny "$got" missing-core-source-guard-deny

printf '\n== %d passed, %d failed ==\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
