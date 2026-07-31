#!/usr/bin/env bash
# strategic-fit-gate: strategic/ICP-fit + compounding-value opening test,
# fired only on partnerships-bd phase-1 proposal writes.
set -uo pipefail

payload="$(cat)"

case "${STRATEGIC_FIT_GATE_OFF:-}" in
  ""|0|false|no|off) : ;;
  *) exit 0 ;;
esac

deny() {
  printf '{"hookSpecificOutput":{"permissionDecision":"deny","permissionDecisionReason":"%s"}}\n' "$1"
  exit 2
}

on_err() {
  echo '{"hookSpecificOutput":{"permissionDecision":"deny","permissionDecisionReason":"strategic-fit-gate: refused — gate crashed, failing closed."}}'
  exit 2
}
trap on_err ERR

command -v python3 >/dev/null 2>&1 || deny "strategic-fit-gate: refused — python3 not available, failing closed."

[ -n "$payload" ] || deny "strategic-fit-gate: refused — empty stdin payload."

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
[ "$first_line" = "__OK__" ] || deny "strategic-fit-gate: refused — malformed or non-dict tool_input."

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

[ "${CLAUDE_ROLE:-}" = "partnerships-bd" ] || exit 0
echo "$rel_path" | grep -Eq '^docs/issue-[0-9]+/proposals/.*\.md$' || exit 0

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
[ "$recon_marker" = "__RECON_OK__" ] || deny "strategic-fit-gate: refused — cannot determine resulting content"
body="$(printf '%s\n' "$resulting_text" | tail -n +2)"

# --- substance check ---------------------------------------------------------
verdict="$(printf '%s' "$body" | python3 -c '
import re, sys

text = sys.stdin.read()

table_pos = None
for m in re.finditer(r"^[ \t]*\|.*\|[ \t]*$", text, re.MULTILINE):
    table_pos = m.start()
    break

fit_pos = None
for pat in (r"(?i)(icp|strategic).{0,20}fit", r"(?i)strategic fit", r"(?i)icp overlap"):
    m = re.search(pat, text)
    if m and (fit_pos is None or m.start() < fit_pos):
        fit_pos = m.start()

cv_m = re.search(r"(?i)compounding.{0,3}value", text)
cv_pos = cv_m.start() if cv_m else None

if fit_pos is None:
    print("DENY_NO_FIT")
elif cv_pos is None:
    print("DENY_NO_COMPOUNDING_VALUE")
elif table_pos is not None and (fit_pos > table_pos or cv_pos > table_pos):
    print("DENY_ORDER")
else:
    print("PASS")
')"

case "$verdict" in
  DENY_NO_FIT)
    deny "strategic-fit-gate: refused — proposal has no strategic-fit/ICP-overlap statement before scoring."
    ;;
  DENY_NO_COMPOUNDING_VALUE)
    deny "strategic-fit-gate: refused — proposal has no compounding-value statement before scoring."
    ;;
  DENY_ORDER)
    deny "strategic-fit-gate: refused — a scoring table appears before the strategic-fit/compounding-value opening statement; wrong-partner deals must not clear the door on scoring alone."
    ;;
esac

exit 0
