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

# --- mandatory cases (issue-10): Edit replace_all, MultiEdit mixed, ------
# malformed-JSON variants, kill-switch unrecognized value, absolute path,
# Bash-tool write into scope. ------------------------------------------------

DUP_GOOD="$GOOD
$GOOD
END_MARKER"

# Edit replace_all:true deletes BOTH copies of the passing block -> no
# stage/citation left -> deny. A first-occurrence-only bug would leave the
# second copy intact and wrongly allow.
td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"
mkdir -p "$td/$(dirname "$TARGET")"
printf '%s' "$DUP_GOOD" > "$td/$TARGET"
printf '{"tool_name":"Edit","tool_input":{"file_path":"%s","old_string":%s,"new_string":"","replace_all":true},"cwd":"%s"}' \
  "$TARGET" "$(python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$GOOD")" "$td" \
  | env CLAUDE_PROJECT_DIR="$td" CLAUDE_ROLE=partnerships-bd /bin/bash "$HOOKS/evidence-discipline-gate.sh" >/dev/null 2>&1
rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
rm -rf "$td"; report deny "$got" edit-replace-all-removes-all-occurrences-deny

# MultiEdit mixed: a replace_all:false edit touches an unrelated marker; a
# replace_all:true edit strips both copies of the passing block.
td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"
mkdir -p "$td/$(dirname "$TARGET")"
printf '%s' "$DUP_GOOD" > "$td/$TARGET"
payload="$(BLOCK="$GOOD" TARGET_PATH="$TARGET" CWD_PATH="$td" python3 -c '
import json, os
edits = [
    {"old_string": "END_MARKER", "new_string": "END_MARKER (checked)", "replace_all": False},
    {"old_string": os.environ["BLOCK"], "new_string": "", "replace_all": True},
]
print(json.dumps({"tool_name": "MultiEdit", "tool_input": {"file_path": os.environ["TARGET_PATH"], "edits": edits}, "cwd": os.environ["CWD_PATH"]}))
')"
printf '%s' "$payload" | env CLAUDE_PROJECT_DIR="$td" CLAUDE_ROLE=partnerships-bd /bin/bash "$HOOKS/evidence-discipline-gate.sh" >/dev/null 2>&1
rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
rm -rf "$td"; report deny "$got" multiedit-mixed-replace-all-deny

# malformed JSON: truncated
td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"
printf '{"tool_name":"Write","tool_inp' | env CLAUDE_PROJECT_DIR="$td" CLAUDE_ROLE=partnerships-bd /bin/bash "$HOOKS/evidence-discipline-gate.sh" >/dev/null 2>&1
rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
rm -rf "$td"; report deny "$got" malformed-json-truncated-deny

# malformed JSON: valid JSON but not an object
td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"
printf '[1,2,3]' | env CLAUDE_PROJECT_DIR="$td" CLAUDE_ROLE=partnerships-bd /bin/bash "$HOOKS/evidence-discipline-gate.sh" >/dev/null 2>&1
rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
rm -rf "$td"; report deny "$got" malformed-json-non-object-deny

# malformed JSON: empty stdin
td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"
printf '' | env CLAUDE_PROJECT_DIR="$td" CLAUDE_ROLE=partnerships-bd /bin/bash "$HOOKS/evidence-discipline-gate.sh" >/dev/null 2>&1
rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
rm -rf "$td"; report deny "$got" malformed-json-empty-stdin-deny

# kill switch: unrecognized/typo value must stay active
td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"
mkdir -p "$td/$(dirname "$TARGET")"
printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":%s},"cwd":"%s"}' \
  "$TARGET" "$(python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$NO_CITATION")" "$td" \
  | env CLAUDE_PROJECT_DIR="$td" CLAUDE_ROLE=partnerships-bd EVIDENCE_DISCIPLINE_GATE_OFF=xyzzy /bin/bash "$HOOKS/evidence-discipline-gate.sh" >/dev/null 2>&1
rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
rm -rf "$td"; report deny "$got" kill-switch-unrecognized-value-stays-active

# absolute file_path matching the same scope a relative fixture matches
td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"
mkdir -p "$td/$(dirname "$TARGET")"
printf '{"tool_name":"Write","tool_input":{"file_path":"%s/%s","content":%s},"cwd":"%s"}' \
  "$td" "$TARGET" "$(python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$NO_CITATION")" "$td" \
  | env CLAUDE_PROJECT_DIR="$td" CLAUDE_ROLE=partnerships-bd /bin/bash "$HOOKS/evidence-discipline-gate.sh" >/dev/null 2>&1
rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
rm -rf "$td"; report deny "$got" absolute-path-deny

# ./-prefixed relative variant
td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"
mkdir -p "$td/$(dirname "$TARGET")"
printf '{"tool_name":"Write","tool_input":{"file_path":"./%s","content":%s},"cwd":"%s"}' \
  "$TARGET" "$(python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$NO_CITATION")" "$td" \
  | env CLAUDE_PROJECT_DIR="$td" CLAUDE_ROLE=partnerships-bd /bin/bash "$HOOKS/evidence-discipline-gate.sh" >/dev/null 2>&1
rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
rm -rf "$td"; report deny "$got" dot-slash-prefixed-path-deny

# a Bash-tool write reaching this gate's scope is refused the same way
td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"
mkdir -p "$td/$(dirname "$TARGET")"
printf '{"tool_name":"Bash","tool_input":{"command":"printf x >> %s"},"cwd":"%s"}' "$TARGET" "$td" \
  | env CLAUDE_PROJECT_DIR="$td" CLAUDE_ROLE=partnerships-bd /bin/bash "$HOOKS/evidence-discipline-gate.sh" >/dev/null 2>&1
rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
rm -rf "$td"; report deny "$got" bash-tool-write-into-scope-deny

# missing-core: guarded source must deny, not silently allow (issue-13/issue-75)
td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"
printf '' | env CLAUDE_PROJECT_DIR="$td" CLAUDE_ROLE=partnerships-bd CLAUDE_PLUGIN_ROOT_CORE="$td/no-such-core" /bin/bash "$HOOKS/evidence-discipline-gate.sh" >/dev/null 2>&1
rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
rm -rf "$td"; report deny "$got" missing-core-source-guard-deny

printf '\n== %d passed, %d failed ==\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
