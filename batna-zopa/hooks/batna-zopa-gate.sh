#!/usr/bin/env bash
# batna-zopa gate: BATNA statement + ZOPA estimate, fired on partnerships-bd
# phase-1 proposal writes and the phase-2 record's deal-structure-verdict.
set -uo pipefail

payload="$(cat)"

[ "${BATNA_ZOPA_GATE_OFF:-}" = "1" ] && exit 0

deny() {
  printf '{"hookSpecificOutput":{"permissionDecision":"deny","permissionDecisionReason":"%s"}}\n' "$1"
  exit 2
}

on_err() {
  echo '{"hookSpecificOutput":{"permissionDecision":"deny","permissionDecisionReason":"batna-zopa: refused — gate crashed, failing closed."}}'
  exit 2
}
trap on_err ERR

command -v python3 >/dev/null 2>&1 || deny "batna-zopa: refused — python3 not available, failing closed."

[ -n "$payload" ] || deny "batna-zopa: refused — empty stdin payload."

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
[ "$first_line" = "__OK__" ] || deny "batna-zopa: refused — malformed or non-dict tool_input."

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

# --- role scope check --------------------------------------------------------
[ "${CLAUDE_ROLE:-}" = "partnerships-bd" ] || exit 0

# --- only this plugin's target surface -------------------------------------
case "$file_path" in
  /*) abs_path="$file_path" ;;
  *) abs_path="$root/$file_path" ;;
esac
rel_path="${abs_path#"$root"/}"

if echo "$rel_path" | grep -Eq '^docs/issue-[0-9]+/proposals/.*\.md$'; then
  :
elif echo "$rel_path" | grep -Eq '^docs/issue-[0-9]+/reports/partnerships-bd\.md$'; then
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
[ "$recon_marker" = "__RECON_OK__" ] || deny "batna-zopa: refused — cannot determine resulting content"
body="$(printf '%s\n' "$resulting_text" | tail -n +2)"

# --- substance checks --------------------------------------------------------
verdict="$(printf '%s' "$body" | python3 -c '
import re, sys

text = sys.stdin.read()

# (a) BATNA presence ----------------------------------------------------------
batna_matches = list(re.finditer(r"(?i)batna", text))
if not batna_matches:
    print("DENY_NO_BATNA")
    sys.exit(0)

# (b) BATNA substance: after stripping the word BATNA and punctuation, at
# least 8 non-whitespace chars of prose remain in the same line or next 2.
lines = text.splitlines()
has_substance = False
for m in batna_matches:
    # find which line this match is on
    upto = text[:m.start()]
    line_no = upto.count("\n")
    window_lines = lines[line_no:line_no + 3]
    window = "\n".join(window_lines)
    stripped = re.sub(r"(?i)batna", "", window)
    stripped = re.sub(r"[^A-Za-z0-9가-힣]+", " ", stripped).strip()
    if len(stripped.replace(" ", "")) >= 8:
        has_substance = True
        break

if not has_substance:
    print("DENY_BATNA_EMPTY")
    sys.exit(0)

# (c) counterpart -> requires ZOPA --------------------------------------------
if re.search(r"(?i)counterpart", text):
    if not re.search(r"(?i)zopa", text):
        print("DENY_NO_ZOPA")
        sys.exit(0)

print("PASS")
')"

case "$verdict" in
  DENY_NO_BATNA)
    deny "batna-zopa: refused — no explicit BATNA (walk-away alternative) stated."
    ;;
  DENY_BATNA_EMPTY)
    deny "batna-zopa: refused — BATNA is named but carries no substantive walk-away description."
    ;;
  DENY_NO_ZOPA)
    deny "batna-zopa: refused — counterpart position is discussed but no ZOPA estimate is stated."
    ;;
esac

exit 0
