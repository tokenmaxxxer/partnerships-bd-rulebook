#!/usr/bin/env bash
# batna-zopa gate, exercised as a real subprocess.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
HOOKS="$HERE/../batna-zopa/hooks"
. "$HERE/lib/resolve-core.sh"
# Convention: docs/specs/test-env-resolution.md (on-the-record issue #551).
CORE_ROOT="$(resolve_core "$HERE/../../core" "$HERE/../../tokenmaxxxer-core/core")" || exit 75
export CLAUDE_PLUGIN_ROOT_CORE="$CORE_ROOT"
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

# --- mandatory cases (issue-10): Edit replace_all, MultiEdit mixed, ------
# malformed-JSON variants, kill-switch unrecognized value, absolute path,
# Bash-tool write into scope. ------------------------------------------------

DUP_PASS="$BATNA_COUNTERPART_ZOPA
$BATNA_COUNTERPART_ZOPA
END_MARKER"

# Edit replace_all:true deletes BOTH copies of the whole passing block ->
# no BATNA/ZOPA left -> deny. A first-occurrence-only bug would leave the
# second copy intact and wrongly allow.
td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"
mkdir -p "$td/$(dirname "$TARGET")"
printf '%s' "$DUP_PASS" > "$td/$TARGET"
printf '{"tool_name":"Edit","tool_input":{"file_path":"%s","old_string":%s,"new_string":"","replace_all":true},"cwd":"%s"}' \
  "$TARGET" "$(python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$BATNA_COUNTERPART_ZOPA")" "$td" \
  | env CLAUDE_PROJECT_DIR="$td" CLAUDE_ROLE=partnerships-bd /bin/bash "$HOOKS/batna-zopa-gate.sh" >/dev/null 2>&1
rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
rm -rf "$td"; report deny "$got" edit-replace-all-removes-all-occurrences-deny

# MultiEdit mixed: a replace_all:false edit only touches an unrelated
# heading; a replace_all:true edit strips both copies of the passing block.
# Overall verdict must still be deny.
td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"
mkdir -p "$td/$(dirname "$TARGET")"
printf '%s' "$DUP_PASS" > "$td/$TARGET"
payload="$(BLOCK="$BATNA_COUNTERPART_ZOPA" TARGET_PATH="$TARGET" CWD_PATH="$td" python3 -c '
import json, os
edits = [
    {"old_string": "END_MARKER", "new_string": "END_MARKER (checked)", "replace_all": False},
    {"old_string": os.environ["BLOCK"], "new_string": "", "replace_all": True},
]
print(json.dumps({"tool_name": "MultiEdit", "tool_input": {"file_path": os.environ["TARGET_PATH"], "edits": edits}, "cwd": os.environ["CWD_PATH"]}))
')"
printf '%s' "$payload" | env CLAUDE_PROJECT_DIR="$td" CLAUDE_ROLE=partnerships-bd /bin/bash "$HOOKS/batna-zopa-gate.sh" >/dev/null 2>&1
rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
rm -rf "$td"; report deny "$got" multiedit-mixed-replace-all-deny

# malformed JSON: truncated
td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"
printf '{"tool_name":"Write","tool_inp' | env CLAUDE_PROJECT_DIR="$td" CLAUDE_ROLE=partnerships-bd /bin/bash "$HOOKS/batna-zopa-gate.sh" >/dev/null 2>&1
rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
rm -rf "$td"; report deny "$got" malformed-json-truncated-deny

# malformed JSON: valid JSON but not an object
td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"
printf '[1,2,3]' | env CLAUDE_PROJECT_DIR="$td" CLAUDE_ROLE=partnerships-bd /bin/bash "$HOOKS/batna-zopa-gate.sh" >/dev/null 2>&1
rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
rm -rf "$td"; report deny "$got" malformed-json-non-object-deny

# malformed JSON: empty stdin
td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"
printf '' | env CLAUDE_PROJECT_DIR="$td" CLAUDE_ROLE=partnerships-bd /bin/bash "$HOOKS/batna-zopa-gate.sh" >/dev/null 2>&1
rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
rm -rf "$td"; report deny "$got" malformed-json-empty-stdin-deny

# kill switch: unrecognized/typo value must stay active
td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"
mkdir -p "$td/$(dirname "$TARGET")"
printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":%s},"cwd":"%s"}' \
  "$TARGET" "$(python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$NO_BATNA")" "$td" \
  | env CLAUDE_PROJECT_DIR="$td" CLAUDE_ROLE=partnerships-bd BATNA_ZOPA_GATE_OFF=xyzzy /bin/bash "$HOOKS/batna-zopa-gate.sh" >/dev/null 2>&1
rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
rm -rf "$td"; report deny "$got" kill-switch-unrecognized-value-stays-active

# absolute file_path matching the same scope a relative fixture matches
td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"
mkdir -p "$td/$(dirname "$TARGET")"
printf '{"tool_name":"Write","tool_input":{"file_path":"%s/%s","content":%s},"cwd":"%s"}' \
  "$td" "$TARGET" "$(python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$NO_BATNA")" "$td" \
  | env CLAUDE_PROJECT_DIR="$td" CLAUDE_ROLE=partnerships-bd /bin/bash "$HOOKS/batna-zopa-gate.sh" >/dev/null 2>&1
rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
rm -rf "$td"; report deny "$got" absolute-path-deny

# ./-prefixed relative variant
td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"
mkdir -p "$td/$(dirname "$TARGET")"
printf '{"tool_name":"Write","tool_input":{"file_path":"./%s","content":%s},"cwd":"%s"}' \
  "$TARGET" "$(python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$NO_BATNA")" "$td" \
  | env CLAUDE_PROJECT_DIR="$td" CLAUDE_ROLE=partnerships-bd /bin/bash "$HOOKS/batna-zopa-gate.sh" >/dev/null 2>&1
rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
rm -rf "$td"; report deny "$got" dot-slash-prefixed-path-deny

# a Bash-tool write reaching this gate's scope is refused the same way
td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"
mkdir -p "$td/$(dirname "$TARGET")"
printf '{"tool_name":"Bash","tool_input":{"command":"printf x >> %s"},"cwd":"%s"}' "$TARGET" "$td" \
  | env CLAUDE_PROJECT_DIR="$td" CLAUDE_ROLE=partnerships-bd /bin/bash "$HOOKS/batna-zopa-gate.sh" >/dev/null 2>&1
rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
rm -rf "$td"; report deny "$got" bash-tool-write-into-scope-deny

# missing-core: guarded source must deny, not silently allow (issue-13/issue-75)
td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"
printf '' | env CLAUDE_PROJECT_DIR="$td" CLAUDE_ROLE=partnerships-bd CLAUDE_PLUGIN_ROOT_CORE="$td/no-such-core" /bin/bash "$HOOKS/batna-zopa-gate.sh" >/dev/null 2>&1
rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
rm -rf "$td"; report deny "$got" missing-core-source-guard-deny

printf '\n== %d passed, %d failed ==\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
