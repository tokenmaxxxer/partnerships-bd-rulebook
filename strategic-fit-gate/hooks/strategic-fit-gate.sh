#!/usr/bin/env bash
# strategic-fit-gate: strategic/ICP-fit + compounding-value opening test,
# fired only on partnerships-bd phase-1 proposal writes.
#
# References core canon `gate-lib.sh`/`gate-lib.py` (issue-72, gate-house
# standard) for trap/kill-switch/path-normalize/reconstruct — never
# reimplemented here (docs/handbooks/canon-scripts.md).
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/gate-lib.sh" || { echo "strategic-fit-gate.sh: cannot source gate-lib.sh" >&2; exit 2; }
gate_trap_fail_closed
set -uo pipefail

GATE_NAME="strategic-fit-gate"
payload="$(cat)"
gate_kill_switch_active "${STRATEGIC_FIT_GATE_OFF:-}" || { trap - EXIT; exit 0; }

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

SCOPE_PATTERN='^docs/issue-[0-9]+/proposals/.*\.md$'

normalize_rel() {
  GATE_LIB_PY="$GATE_LIB_PY" python3 -c '
import importlib.util, os, sys
spec = importlib.util.spec_from_file_location("gate_lib", os.environ["GATE_LIB_PY"])
gate_lib = importlib.util.module_from_spec(spec); spec.loader.exec_module(gate_lib)
rel = gate_lib.gate_normalize_path(sys.argv[1], sys.argv[2])
print(rel if rel is not None else "")
' "$root" "$1"
}

# --- Bash-tool write detection: same scope, content unreconstructable -------
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

# --- reconstruct resulting text via gate-lib --------------------------------
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

# --- substance check: heading/section presence, not bare substring ---------
verdict="$(printf '%s' "$body" | python3 -c '
import re, sys

text = sys.stdin.read()

table_pos = None
for m in re.finditer(r"^[ \t]*\|.*\|[ \t]*$", text, re.MULTILINE):
    table_pos = m.start()
    break

# A section is a markdown heading whose text matches the topic, OR a
# paragraph opening with the topic phrase (bold/plain) followed by ":" —
# not a bare substring occurring anywhere (issue-10 item 2: section /
# structural anchoring, not "the word appears somewhere").
def section_pos(heading_res, para_res):
    best = None
    for pat in heading_res:
        m = re.search(pat, text, re.MULTILINE | re.IGNORECASE)
        if m and (best is None or m.start() < best):
            best = m.start()
    for pat in para_res:
        m = re.search(pat, text, re.IGNORECASE)
        if m and (best is None or m.start() < best):
            best = m.start()
    return best

fit_pos = section_pos(
    [r"^#{1,6}\s*.*(strategic|icp).{0,20}fit"],
    [r"(?m)^\**(strategic fit|icp fit|icp overlap)\**\s*:", r"(?i)(icp|strategic)\s{0,3}fit"],
)

cv_pos = section_pos(
    [r"^#{1,6}\s*.*compounding.{0,3}value"],
    [r"(?m)^\**compounding.?value\**\s*:", r"(?i)compounding.{0,3}value"],
)

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
    gate_deny "$GATE_NAME" "proposal has no strategic-fit/ICP-overlap statement before scoring."
    ;;
  DENY_NO_COMPOUNDING_VALUE)
    gate_deny "$GATE_NAME" "proposal has no compounding-value statement before scoring."
    ;;
  DENY_ORDER)
    gate_deny "$GATE_NAME" "a scoring table appears before the strategic-fit/compounding-value opening statement; wrong-partner deals must not clear the door on scoring alone."
    ;;
  PASS)
    gate_allow
    ;;
  *)
    gate_deny "$GATE_NAME" "unrecognized verdict from substance check: $verdict"
    ;;
esac
