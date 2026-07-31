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

printf '\n== %d passed, %d failed ==\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
