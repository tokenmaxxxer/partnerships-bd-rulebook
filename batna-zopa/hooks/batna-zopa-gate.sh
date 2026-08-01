#!/usr/bin/env bash
# batna-zopa gate: BATNA statement + ZOPA estimate, fired on partnerships-bd
# phase-1 proposal writes and the phase-2 record's deal-structure-verdict.
#
# References core canon `gate-lib.sh`/`gate-lib.py` (issue-72, gate-house
# standard) for trap/kill-switch/path-normalize/reconstruct — never
# reimplemented here (docs/handbooks/canon-scripts.md).
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/gate-lib.sh" || { echo "batna-zopa-gate.sh: cannot source gate-lib.sh" >&2; exit 2; }
gate_trap_fail_closed
set -uo pipefail

GATE_NAME="batna-zopa"
payload="$(cat)"
gate_kill_switch_active "${BATNA_ZOPA_GATE_OFF:-}" || { trap - EXIT; exit 0; }

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

# --- substance checks: section/adjacency, not bare substring (issue-10 #2) --
verdict="$(printf '%s' "$body" | python3 -c '
import re, sys

text = sys.stdin.read()
lines = text.splitlines()

def para_index(pos):
    return len(re.split(r"\n\s*\n", text[:pos])) - 1

paragraphs = re.split(r"\n\s*\n", text)

# (a) BATNA presence ----------------------------------------------------------
batna_matches = list(re.finditer(r"(?i)batna", text))
if not batna_matches:
    print("DENY_NO_BATNA")
    sys.exit(0)

# (b) BATNA substance, anchored: the 3-line window around a "batna" mention
# must ALSO carry a heading marker or a list marker (ruling out a bare
# inline mention floating in unrelated prose), and after stripping the word
# and punctuation still have >=8 non-whitespace chars of prose.
has_substance = False
for m in batna_matches:
    upto = text[:m.start()]
    line_no = upto.count("\n")
    window_lines = lines[line_no:line_no + 3]
    window = "\n".join(window_lines)
    anchored = any(
        re.match(r"^\s*(#{1,6}\s|[-*]\s|\d+[.)]\s|\**batna\**\s*:)", l, re.IGNORECASE)
        for l in window_lines
    )
    stripped = re.sub(r"(?i)batna", "", window)
    stripped = re.sub(r"[^A-Za-z0-9가-힣]+", " ", stripped).strip()
    if anchored and len(stripped.replace(" ", "")) >= 8:
        has_substance = True
        break

if not has_substance:
    print("DENY_BATNA_EMPTY")
    sys.exit(0)

# (c) counterpart -> requires a ZOPA claim in the same structural
# neighborhood, not just the word "zopa" occurring anywhere in the document.
# A counterpart-position claim is: a heading matching counterpart/상대방/
# 저쪽/카운터파트, OR a paragraph containing a counterpart noun near a
# position/ask verb (요구|position|ask|제시).
counterpart_heading_re = re.compile(r"(?im)^#{1,6}\s*.*(counterpart|상대방|저쪽|카운터파트)")
counterpart_para_re = re.compile(r"(?i)(상대\s*방?|counterpart|저쪽).{0,40}(요구|position|ask|제시|propos)|(요구|position|ask|제시|propos).{0,40}(상대\s*방?|counterpart|저쪽)")

counterpart_para_idx = None
if counterpart_heading_re.search(text):
    m = counterpart_heading_re.search(text)
    counterpart_para_idx = para_index(m.start())
else:
    for i, p in enumerate(paragraphs):
        if counterpart_para_re.search(p):
            counterpart_para_idx = i
            break

if counterpart_para_idx is not None:
    zopa_heading_re = re.compile(r"(?im)^#{1,6}\s*.*zopa")
    zopa_para_idx = None
    if zopa_heading_re.search(text):
        zopa_para_idx = para_index(zopa_heading_re.search(text).start())
    else:
        for i, p in enumerate(paragraphs):
            if re.search(r"(?i)zopa", p):
                zopa_para_idx = i
                break
    if zopa_para_idx is None or abs(zopa_para_idx - counterpart_para_idx) > 2:
        print("DENY_NO_ZOPA")
        sys.exit(0)

print("PASS")
')"

case "$verdict" in
  DENY_NO_BATNA)
    gate_deny "$GATE_NAME" "no explicit BATNA (walk-away alternative) stated."
    ;;
  DENY_BATNA_EMPTY)
    gate_deny "$GATE_NAME" "BATNA is named but carries no structurally-anchored, substantive walk-away description."
    ;;
  DENY_NO_ZOPA)
    gate_deny "$GATE_NAME" "a counterpart position is discussed but no ZOPA claim appears in the same structural neighborhood (heading or adjacent paragraph)."
    ;;
  PASS)
    gate_allow
    ;;
  *)
    gate_deny "$GATE_NAME" "unrecognized verdict from substance check: $verdict"
    ;;
esac
