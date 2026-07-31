#!/usr/bin/env bash
# term-sheet-structure gate: 7-subsection term-sheet norm, fired only on the
# partnerships-bd phase-2 record's term-sheet-outline field.
set -uo pipefail

payload="$(cat)"

[ "${TERM_SHEET_STRUCTURE_GATE_OFF:-}" = "1" ] && exit 0

deny() {
  printf '{"hookSpecificOutput":{"permissionDecision":"deny","permissionDecisionReason":"%s"}}\n' "$1"
  exit 2
}

on_err() {
  echo '{"hookSpecificOutput":{"permissionDecision":"deny","permissionDecisionReason":"term-sheet-structure: refused — gate crashed, failing closed."}}'
  exit 2
}
trap on_err ERR

command -v python3 >/dev/null 2>&1 || deny "term-sheet-structure: refused — python3 not available, failing closed."

[ -n "$payload" ] || deny "term-sheet-structure: refused — empty stdin payload."

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
[ "$first_line" = "__OK__" ] || deny "term-sheet-structure: refused — malformed or non-dict tool_input."

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
echo "$rel_path" | grep -Eq '^docs/issue-[0-9]+/reports/partnerships-bd\.md$' || exit 0

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
[ "$recon_marker" = "__RECON_OK__" ] || deny "term-sheet-structure: refused — cannot determine resulting content"
body="$(printf '%s\n' "$resulting_text" | tail -n +2)"

# --- substance check ---------------------------------------------------------
verdict="$(printf '%s' "$body" | python3 -c '
import re, sys

text = sys.stdin.read()
low = text.lower()

# does this write even attempt to carry a term-sheet-outline?
mentions_title = ("term-sheet-outline" in low) or ("term sheet outline" in low)

patterns = {
    "purpose": r"purpose",
    "roles & responsibilities": r"roles?\s*(&|and)?\s*responsibilit",
    "governance": r"governance",
    "kpis": r"kpis?|key performance indicator",
    "dispute resolution": r"dispute\s*resolution",
    "exit/termination": r"exit|termination",
}

def has_terms():
    for line in text.splitlines():
        if re.search(r"^#{1,6}\s|^\*\*|^[0-9]+[.)]\s", line, re.IGNORECASE) and re.search(r"\bterms\b", line, re.IGNORECASE):
            return True
    if re.search(r"(?i)\bterms?\b.{0,20}(profit.?sharing|capital.?contribution|value)", text):
        return True
    return False

found = {}
for name, pat in patterns.items():
    found[name] = bool(re.search(pat, text, re.IGNORECASE))
found["terms"] = has_terms()

keyword_count = sum(1 for v in found.values() if v)

if not mentions_title and keyword_count < 2:
    print("PASS")
    sys.exit(0)

order = ["purpose", "roles & responsibilities", "terms", "governance", "kpis", "dispute resolution", "exit/termination"]
missing = [name for name in order if not found[name]]

# governance/kpis glued-together check
merged = bool(re.search(r"(?i)governance\s*[/&+]\s*kpis?", text)) or bool(re.search(r"(?i)kpis?\s*[/&+]\s*governance", text))

if missing == ["exit/termination"]:
    print("DENY_MISSING_EXIT")
    sys.exit(0)

if merged:
    print("DENY_GOVERNANCE_KPI_MERGED")
    sys.exit(0)

if missing:
    print("DENY_MISSING_SUBSECTIONS:" + ",".join(missing))
    sys.exit(0)

print("PASS")
')"

case "$verdict" in
  DENY_MISSING_EXIT)
    deny "term-sheet-structure: refused — exit/termination clause is missing; it is non-optional."
    ;;
  DENY_MISSING_SUBSECTIONS:*)
    missing_list="${verdict#DENY_MISSING_SUBSECTIONS:}"
    deny "term-sheet-structure: refused — missing required sub-section(s): ${missing_list}."
    ;;
  DENY_GOVERNANCE_KPI_MERGED)
    deny "term-sheet-structure: refused — governance and KPIs must be kept as distinct sub-sections, not merged."
    ;;
esac

exit 0
