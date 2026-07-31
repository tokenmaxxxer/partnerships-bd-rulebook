#!/usr/bin/env bash
# multi-axis-scoring gate: weighted six-axis evaluation table required on
# the partnerships-bd phase-1 proposal and phase-2 record surfaces.
set -uo pipefail

payload="$(cat)"

[ "${MULTI_AXIS_SCORING_GATE_OFF:-}" = "1" ] && exit 0

deny() {
  printf '{"hookSpecificOutput":{"permissionDecision":"deny","permissionDecisionReason":"%s"}}\n' "$1"
  exit 2
}

on_err() {
  echo '{"hookSpecificOutput":{"permissionDecision":"deny","permissionDecisionReason":"multi-axis-scoring: refused — gate crashed, failing closed."}}'
  exit 2
}
trap on_err ERR

command -v python3 >/dev/null 2>&1 || deny "multi-axis-scoring: refused — python3 not available, failing closed."

[ -n "$payload" ] || deny "multi-axis-scoring: refused — empty stdin payload."

parsed="$(printf '%s' "$payload" | python3 -c '
import json, sys
try:
    data = json.load(sys.stdin)
except Exception:
    print("__PARSE_ERROR__")
    sys.exit(0)
if not isinstance(data, dict):
    print("__PARSE_ERROR__")
    sys.exit(0)
tool_input = data.get("tool_input")
if not isinstance(tool_input, dict):
    print("__PARSE_ERROR__")
    sys.exit(0)
tool_name = data.get("tool_name", "")
file_path = tool_input.get("file_path", "")
cwd = data.get("cwd", "")
print("__OK__")
print(tool_name)
print(file_path)
print(cwd)
' 2>/dev/null)"

first_line="$(printf '%s\n' "$parsed" | sed -n '1p')"
[ "$first_line" = "__OK__" ] || deny "multi-axis-scoring: refused — malformed or non-dict tool_input."

tool_name="$(printf '%s\n' "$parsed" | sed -n '2p')"
file_path="$(printf '%s\n' "$parsed" | sed -n '3p')"
cwd="$(printf '%s\n' "$parsed" | sed -n '4p')"

# --- resolve project root --------------------------------------------------
_plausible() { [ -n "${1:-}" ] && [ -d "$1" ]; }

root=""
if _plausible "${CLAUDE_PROJECT_DIR:-}"; then
  root="$CLAUDE_PROJECT_DIR"
elif root="$(git -C "${cwd:-.}" rev-parse --show-toplevel 2>/dev/null)"; then
  :
else
  root="${cwd:-$(pwd -P)}"
fi

# --- only this plugin's target surface -------------------------------------
case "$file_path" in
  /*) abs_path="$file_path" ;;
  *) abs_path="$root/$file_path" ;;
esac
rel_path="${abs_path#"$root"/}"

# scope check: only for partnerships-bd role, on proposal or record path
[ "${CLAUDE_ROLE:-}" = "partnerships-bd" ] || exit 0

if printf '%s' "$rel_path" | grep -Eq '^docs/issue-[0-9]+/proposals/.*\.md$'; then
  :
elif printf '%s' "$rel_path" | grep -Eq '^docs/issue-[0-9]+/reports/partnerships-bd\.md$'; then
  :
else
  exit 0
fi

# --- reconstruct resulting text --------------------------------------------
resulting_text="$(python3 -c '
import json, sys

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

if tool_name == "Write":
    content = tool_input.get("content")
    if content is None:
        print("__RECON_ERROR__")
        sys.exit(0)
    print("__RECON_OK__")
    print(content, end="")
    sys.exit(0)

if tool_name == "Edit":
    old_string = tool_input.get("old_string")
    new_string = tool_input.get("new_string")
    if old_string is None or new_string is None:
        print("__RECON_ERROR__")
        sys.exit(0)
    current = read_current()
    if current is None:
        print("__RECON_ERROR__")
        sys.exit(0)
    if old_string not in current:
        print("__RECON_ERROR__")
        sys.exit(0)
    result = current.replace(old_string, new_string, 1)
    print("__RECON_OK__")
    print(result, end="")
    sys.exit(0)

if tool_name == "MultiEdit":
    edits = tool_input.get("edits")
    if not isinstance(edits, list) or not edits:
        print("__RECON_ERROR__")
        sys.exit(0)
    current = read_current()
    if current is None:
        print("__RECON_ERROR__")
        sys.exit(0)
    for e in edits:
        if not isinstance(e, dict):
            print("__RECON_ERROR__")
            sys.exit(0)
        old_string = e.get("old_string")
        new_string = e.get("new_string")
        if old_string is None or new_string is None:
            print("__RECON_ERROR__")
            sys.exit(0)
        if old_string not in current:
            print("__RECON_ERROR__")
            sys.exit(0)
        current = current.replace(old_string, new_string, 1)
    print("__RECON_OK__")
    print(current, end="")
    sys.exit(0)

print("__RECON_ERROR__")
' "$payload" "$abs_path")"

recon_marker="$(printf '%s\n' "$resulting_text" | sed -n '1p')"
[ "$recon_marker" = "__RECON_OK__" ] || deny "multi-axis-scoring: refused — cannot determine resulting content"
body="$(printf '%s\n' "$resulting_text" | tail -n +2)"

# --- substance check: six axes each with weight+score nearby ---------------
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

failed = []
for name, pattern in axes:
    found = False
    for i, line in enumerate(lines):
        if pattern.search(line):
            window = "\n".join(lines[i:i+3])
            if weight_score_re.search(window) and digit_re.search(window):
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
    exit 0
    ;;
  DENY_MISSING_AXES:*)
    list="${verdict#DENY_MISSING_AXES:}"
    deny "multi-axis-scoring: refused — missing weight+score for required axis/axes: $list."
    ;;
esac

exit 0
