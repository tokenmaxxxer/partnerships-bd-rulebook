#!/usr/bin/env bash
# multi-axis-scoring gate: weighted six-axis evaluation table required on
# the partnerships-bd phase-1 proposal and phase-2 record surfaces.
#
# References core canon `gate-lib.sh`/`gate-lib.py` (issue-72, gate-house
# standard) for trap/kill-switch/path-normalize/reconstruct — never
# reimplemented here (docs/handbooks/canon-scripts.md).
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/gate-lib.sh" || { echo "multi-axis-scoring-gate.sh: cannot source gate-lib.sh" >&2; exit 2; }
gate_trap_fail_closed
set -uo pipefail

GATE_NAME="multi-axis-scoring"
payload="$(cat)"
gate_kill_switch_active "${MULTI_AXIS_SCORING_GATE_OFF:-}" || { trap - EXIT; exit 0; }

command -v python3 >/dev/null 2>&1 || gate_deny "$GATE_NAME" "python3 not available, failing closed."
[ -n "$payload" ] || gate_deny "$GATE_NAME" "empty stdin payload."

parsed="$(printf '%s' "$payload" | python3 -c '
import importlib.util, os, sys

spec = importlib.util.spec_from_file_location("gate_lib", os.environ["GATE_LIB_PY"])
gate_lib = importlib.util.module_from_spec(spec)
spec.loader.exec_module(gate_lib)

def deny(msg):
    print("__DENY__")
    print(msg)
    sys.exit(0)

event = gate_lib.gate_parse_json_or_deny(sys.stdin.read(), deny)
tool_input = event.get("tool_input")
if not isinstance(tool_input, dict):
    deny("the tool-call payload is not a JSON object; failing closed")
tool_name = event.get("tool_name", "")
file_path = tool_input.get("file_path", "")
cwd = event.get("cwd", "")
command = tool_input.get("command", "") if tool_name == "Bash" else ""
print("__OK__")
print(tool_name)
print(file_path)
print(cwd)
print(command)
' 2>/dev/null)"

marker="$(printf '%s\n' "$parsed" | sed -n '1p')"
if [ "$marker" = "__DENY__" ]; then
  gate_deny "$GATE_NAME" "$(printf '%s\n' "$parsed" | sed -n '2p')"
fi
[ "$marker" = "__OK__" ] || gate_deny "$GATE_NAME" "malformed or non-dict tool_input."

tool_name="$(printf '%s\n' "$parsed" | sed -n '2p')"
file_path="$(printf '%s\n' "$parsed" | sed -n '3p')"
cwd="$(printf '%s\n' "$parsed" | sed -n '4p')"
bash_command="$(printf '%s\n' "$parsed" | sed -n '5p')"

# --- resolve + realpath the project root -----------------------------------
_plausible() { [ -n "${1:-}" ] && [ -d "$1" ]; }

root=""
if _plausible "${CLAUDE_PROJECT_DIR:-}"; then
  root="$CLAUDE_PROJECT_DIR"
elif root="$(git -C "${cwd:-.}" rev-parse --show-toplevel 2>/dev/null)"; then
  :
else
  root="${cwd:-$(pwd -P)}"
fi
root="$(cd "$root" 2>/dev/null && pwd -P || printf '%s' "$root")"

[ "${CLAUDE_ROLE:-}" = "partnerships-bd" ] || exit 0

SCOPE_PATTERN='^docs/issue-[0-9]+/(proposals/.*\.md|reports/partnerships-bd\.md)$'

normalize_rel() {
  GATE_LIB_PY="$GATE_LIB_PY" python3 -c '
import importlib.util, os, sys
spec = importlib.util.spec_from_file_location("gate_lib", os.environ["GATE_LIB_PY"])
gate_lib = importlib.util.module_from_spec(spec); spec.loader.exec_module(gate_lib)
rel = gate_lib.gate_normalize_path(sys.argv[1], sys.argv[2])
print(rel if rel is not None else "")
' "$root" "$1"
}

if [ "$tool_name" = "Bash" ]; then
  while IFS= read -r tok; do
    [ -n "$tok" ] || continue
    tok_rel="$(normalize_rel "$tok")"
    [ -n "$tok_rel" ] || continue
    if printf '%s' "$tok_rel" | grep -Eq "$SCOPE_PATTERN"; then
      gate_deny "$GATE_NAME" "a Bash-tool command writes into this gate's scope ($tok_rel); refusing rather than letting a Bash write bypass Write/Edit/MultiEdit review."
    fi
  done <<EOF
$(gate_bash_write_targets "$bash_command")
EOF
  exit 0
fi

rel_path="$(normalize_rel "$file_path")"
[ -n "$rel_path" ] || exit 0
printf '%s' "$rel_path" | grep -Eq "$SCOPE_PATTERN" || exit 0

case "$file_path" in
  /*) abs_path="$file_path" ;;
  *) abs_path="$root/$file_path" ;;
esac

resulting_text="$(python3 -c '
import importlib.util, json, os, sys

spec = importlib.util.spec_from_file_location("gate_lib", os.environ["GATE_LIB_PY"])
gate_lib = importlib.util.module_from_spec(spec)
spec.loader.exec_module(gate_lib)

payload = sys.argv[1]
abs_path = sys.argv[2]

try:
    data = json.loads(payload)
except Exception:
    print("__RECON_ERROR__")
    sys.exit(0)

tool_name = data.get("tool_name", "")
tool_input = data.get("tool_input", {})

def read_current():
    try:
        with open(abs_path, "r") as f:
            return f.read()
    except Exception:
        return None

current_content = read_current() if tool_name != "Write" else None
text, ok = gate_lib.gate_reconstruct_write(tool_name, tool_input, current_content)
if not ok:
    print("__RECON_ERROR__")
    sys.exit(0)
print("__RECON_OK__")
print(text, end="")
' "$payload" "$abs_path")"

recon_marker="$(printf '%s\n' "$resulting_text" | sed -n '1p')"
[ "$recon_marker" = "__RECON_OK__" ] || gate_deny "$GATE_NAME" "cannot determine resulting content"
body="$(printf '%s\n' "$resulting_text" | tail -n +2)"

# --- substance check: six axes, each anchored to a heading/list item with
# a weight+score+digit in the same structural window (not a bare substring
# match anywhere in the document).
verdict="$(printf '%s' "$body" | python3 -c '
import re, sys

text = sys.stdin.read()
lines = text.splitlines()

axes = [
    ("strategic/ICP fit", re.compile(r"(?i)(strategic.{0,10}fit|icp.{0,10}fit)")),
    ("financial health", re.compile(r"(?i)financial.{0,10}health")),
    ("legal/compliance posture", re.compile(r"(?i)(legal.{0,15}(compliance|posture)|compliance.{0,15}posture)")),
    ("operational capability", re.compile(r"(?i)operational.{0,10}capabilit")),
    ("cultural fit", re.compile(r"(?i)cultural.{0,10}fit")),
    ("compounding-value", re.compile(r"(?i)compounding.{0,3}value")),
]

weight_score_re = re.compile(r"(?i)\b(weight|score)\b")
digit_re = re.compile(r"\d")
anchor_re = re.compile(r"^\s*(#{1,6}\s|[-*]\s|\d+[.)]\s|\|)")

failed = []
for name, pattern in axes:
    found = False
    for i, line in enumerate(lines):
        if pattern.search(line):
            window = lines[i:i+3]
            joined = "\n".join(window)
            anchored = any(anchor_re.search(l) for l in window)
            if anchored and weight_score_re.search(joined) and digit_re.search(joined):
                found = True
                break
    if not found:
        failed.append(name)

if not failed:
    print("PASS")
else:
    print("DENY_MISSING_AXES:" + ",".join(failed))
')"

case "$verdict" in
  PASS)
    gate_allow
    ;;
  DENY_MISSING_AXES:*)
    list="${verdict#DENY_MISSING_AXES:}"
    gate_deny "$GATE_NAME" "missing structurally-anchored weight+score for required axis/axes: $list."
    ;;
  *)
    gate_deny "$GATE_NAME" "unrecognized verdict from substance check: $verdict"
    ;;
esac
