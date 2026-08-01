# issue-10 phase-1 proposal: gate A+ remediation design

Status: PROPOSAL — phase 1 only, execution deferred to phase-2 approval per
role-handoff contract v3 s19. No APPROVE issued here.

Full defect evidence: `docs/issue-10/reports/partnerships-bd/survey.md`.

## Stage

Non-binding: this is a design proposal for internal gate tooling, not a
deal term sheet — there is no counterparty and no binding-terms-ready
stage applicable to this subject matter.

## Strategic fit and compounding value

This remediation is a strategic/ICP fit for the partnerships-bd role's own
tooling: a role whose entire job is judging whether a deal structurally
holds cannot itself run on gates graded B- for exactly the failure modes
(lost deny reasons, fail-open kill switches, substring-deep semantic
checks) that a real deal-structure audit would flag in a counterparty's
own compliance tooling — fixing our own gates to A+ is prerequisite
credibility, not incidental cleanup.

Compounding-value: adopting the core canon library once, here, means every
future methodology gate this role adds inherits fail-closed/kill-switch/
reconstruct/path-normalize correctness for free, instead of re-deriving
(and re-breaking) the same five shapes again — the same compounding
argument core's own gate-house-standard.md makes for the other 42
downstream rulebooks.

## BATNA and ZOPA

BATNA (walk-away alternative): if this remediation proposal is not
approved, the 5 gates continue running at their current B- grade — lost
deny reasons, a fail-open kill switch, and substring-only semantic checks
stay live — which is an acceptable but strictly worse fallback than
landing this fix, since the gates still fail closed on crash/malformed
input even in their current state; nothing about walking away from this
proposal breaks anything that isn't already broken today.

No external counterparty is party to this proposal (it is internal
tooling against this repo's own gates), so no ZOPA estimate applies.

## Source

Source: `core/hooks/lib/gate-lib.sh`, `core/hooks/lib/gate-lib.py`, and
`docs/handbooks/gate-house-standard.md` (issue-72, landed) — the canon
this proposal reference-adopts; full citations to specific functions and
line ranges appear inline in "Design principle" and the survey.

## Six-axis scoring (applying multi-axis-scoring's own doctrine to this remediation)

- strategic/ICP fit: weight 3, score 5 — see "Strategic fit and
  compounding value" above.
- financial health: weight 1, score 5 — zero external cost, internal-repo
  change, no vendor/spend.
- legal/compliance posture: weight 2, score 5 — closes the fail-open
  kill-switch and lost-deny-reason gaps, i.e. improves compliance posture
  directly.
- operational capability: weight 2, score 4 — requires phase-2 execution
  capacity across 5 gate scripts + README + tests, feasible in one branch.
- cultural fit: weight 1, score 5 — matches the repo's existing
  reference-not-vendor convention (`directive.sh` already does this).
- compounding-value: weight 3, score 5 — see "Strategic fit and
  compounding value" above.

## Design principle

Reference-adopt `core/hooks/lib/gate-lib.sh` + `gate-lib.py`
(`docs/handbooks/gate-house-standard.md`) into all 5 methodology gates.
Never vendor a copy (`docs/handbooks/canon-scripts.md`'s rule) — source/
import it the same way `directive.sh` already sources
`core/hooks/lib/role-directive.sh`, via
`${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}`.
No gate re-derives its own trap/kill-switch/path-normalize/reconstruct
logic after this migration; every one of those shapes becomes a `gate_*`
call.

## Per-defect fix, mapped to the adopted library

| Survey defect | Fix | Library call |
|---|---|---|
| 1. deny() writes JSON to stdout, exit 2 | Replace every gate's hand-rolled `deny()`/`on_err` with `gate_trap_fail_closed` (installed as the *first* statement, before `set -uo pipefail`, so a syntax error or unset-var abort is still caught) + `gate_deny "<gate-name>" "<reason>"` (stderr-only) / `gate_allow` | `gate_trap_fail_closed`, `gate_deny`, `gate_allow` |
| 2. kill-switch backwards (strategic-fit-gate) / narrow (other 4) | Replace both shapes with one call: `gate_kill_switch_active "${X_GATE_OFF:-}" \|\| { trap - EXIT; exit 0; }` — unrecognized value stays active, only `1/true/yes/on` (case-insensitive) disables | `gate_kill_switch_active` |
| 3. no realpath, loose root/path matching | Root resolution (`CLAUDE_PROJECT_DIR` → `git rev-parse --show-toplevel` → cwd fallback) is kept as-is (not in gate-lib's scope — it resolves the library's own dir, not the project root) but callers must `realpath` the resolved root before path-matching; then feed both root and `file_path` into `gate_lib.gate_normalize_path(root, path)` for the root-relative tail instead of bare string-strip | `gate_normalize_path` (Python payload) |
| 4. replace_all ignored on Edit/MultiEdit | Replace every gate's inline reconstruction Python (Write/Edit/MultiEdit hand-rolled `.replace(..., 1)`) with `gate_lib.gate_reconstruct_write(tool, tool_input, current_content)`, loaded via the documented `importlib.util.spec_from_file_location` against `os.environ["GATE_LIB_PY"]` | `gate_reconstruct_write` |
| 5. ZOPA/BATNA substring-only semantics | Not covered by gate-lib (out of its scope — it's a payload-parsing/write-mechanics library, not a doctrine-semantics one). Addressed separately below. | — |

`gate_bash_write_targets` is adopted defensively even though none of the 5
gates currently match `Bash`-tool writes — the standard's mandatory test
case 6 (a `Bash`-tool write reaching the same target a `Write` call would
hit) requires it to be exercised, and a proposal author bypassing these
gates via `Bash echo >> docs/issue-N/proposals/x.md` is a real gap today.

## Semantic-check upgrade: substring → section/adjacency/structure

Issue requirement #2. Two concrete upgrades, one per current substring
check, kept inside each gate's own Python payload (gate-lib does not own
doctrine semantics):

1. **ZOPA's "counterpart" gate → section-presence, not word-presence.**
   Replace `re.search(r"(?i)counterpart", text)` with a markdown-heading
   scan: does the document have a heading matching
   `r"(?im)^#{1,6}\s*.*(counterpart|상대방|저쪽|카운터파트)"`, OR does the
   BATNA-context window (already computed for defect-check (b)) contain a
   sentence with an explicit position/ask verb near a counterpart noun
   (`상대(방)?|counterpart|저쪽` within the same paragraph as
   `요구|position|ask|제시`)? Either hit requires a ZOPA section to also be
   present, checked the same way (heading match on
   `r"(?im)^#{1,6}\s*.*zopa"` OR a paragraph-adjacency check: a paragraph
   containing "zopa" within 2 paragraphs of the counterpart-position
   paragraph). This moves the check from "the word appears anywhere in the
   whole document" to "a counterpart-position claim and a ZOPA claim occupy
   the same structural neighborhood" — a proposal that mentions "counterpart"
   once in an unrelated aside no longer trips it, and a proposal that
   discusses the other side's ask under a differently-worded heading (no
   literal "counterpart" token) now does.
2. **BATNA's substance check → keep the windowed-context technique
   (already adjacency-based, not pure substring) but require it anchor to
   a heading or list-item, not just any 3-line window.** Current check
   (survey defect 5, batna-zopa-gate.sh:180-194) already looks at a 3-line
   window around each "batna" match — this is upgraded, not replaced: the
   window must additionally contain either a markdown heading marker
   (`^#{1,6}`) or a list marker (`^[-*]|^\d+\.`) within those 3 lines,
   ruling out a bare inline mention with no structural anchoring (e.g.
   "batna" appearing mid-sentence in unrelated prose).
3. Apply the same section/adjacency pattern to the other 4 gates'
   doctrine-specific checks during migration (`strategic-fit-gate`'s
   ICP-fit test, `multi-axis-scoring`'s axis-coverage test,
   `evidence-discipline`'s claim-evidence test, `term-sheet-structure`'s
   outline-structure test) — each currently greps for its domain keyword;
   each gets the same heading-or-list-anchored-window treatment, scoped to
   that gate's own doctrine keyword set (detailed per-gate in phase-2, not
   enumerated here since it requires reading each gate's specific
   substance-check block, which this proposal treats as execution work).

## Mandatory test cases (phase-2 requirement, issue #10 item 3)

Every one of the 5 gates' own `tests/<plugin>-tests.sh` gains these cases
(mirroring `run-gate-lib-tests.sh`'s 6 mandatory groups, adapted to each
gate's real write surface):

1. `Edit` with `replace_all: true` against a multiply-occurring
   `old_string` → reconstructed content reflects all replacements, not
   just the first.
2. `MultiEdit` with a mix of `replace_all: true`/`false` edits in one call.
3. Malformed JSON payload (truncated, non-object, empty stdin) → deny,
   fail-closed.
4. Kill-switch env var set to an unrecognized value (e.g. a typo) → gate
   stays **active** (this is the regression test for defect 2 — without it,
   the backwards case-statement bug is exactly the kind of thing that
   silently reappears).
5. Absolute `file_path` matching the same scope a relative-path fixture
   already matches, plus a `./`-prefixed variant.
6. A `Bash`-tool file write (`{"command": "echo x >> docs/issue-N/..."}`)
   reaching the same target a `Write`-tool call would hit, refused the
   same way.

Plus one semantic-upgrade regression case per gate: a fixture where the
old substring check would have passed (keyword present but structurally
unanchored/off-topic) now correctly denies, and a fixture with a
differently-worded-but-structurally-present section now correctly passes.

`tests/run-gate-tests.sh` (repo-wide aggregator) must show the full suite
green at delivery, per issue #10 item 3's "배송 상태에서 전 스위트
green."

## README realignment (issue #10 item 4)

- Remove the three ghost files from `partnerships-bd/hooks/` in Layout
  (`record-fields-gate.sh`, `trailer-gate.sh`, `handbook-trigger-gate.sh`)
  — these are core canon, never vendored here; replace with an accurate
  statement that `partnerships-bd/hooks/` contains `directive.sh`,
  `hooks.json`, `record-fields.config`, and that role-level gates are core
  canon invoked by path (matching how `role-gates-tests.md` documents
  `core/hooks/tests/stub-check.sh`'s invocation, not vendoring).
  Cross-reference with `${CLAUDE_PLUGIN_ROOT_CORE:-...}` idiom `directive.sh`
  already uses.
- Add a Kill switches section documenting all 5 methodology plugins' env
  vars (`STRATEGIC_FIT_GATE_OFF`, `MULTI_AXIS_SCORING_GATE_OFF`,
  `BATNA_ZOPA_GATE_OFF`, `EVIDENCE_DISCIPLINE_GATE_OFF`,
  `TERM_SHEET_STRUCTURE_GATE_OFF`) and the fixed on-spelling set
  (`1`/`true`/`yes`/`on`, case-insensitive) post-migration.
- Note the `gate-lib.sh`/`gate-lib.py` dependency in the Methodology
  plugins section, alongside the existing per-plugin bullet list.

## Compliance verification (phase-2 exit criterion)

Run
`"${CORE_PLUGIN_ROOT:-$CLAUDE_PLUGIN_ROOT/../core}/hooks/tests/compliance-check.sh" "$(dirname "$0")/.."`
against this repo's hooks directories before and after migration; the
before-run's violation list is the phase-2 work-list, the after-run must
be clean, cited as delivery evidence — matching `gate-house-standard.md`'s
own per-repo migration checklist steps 1 and 4.

## Explicitly out of scope for this proposal

- Any change to `core/hooks/lib/gate-lib.sh`/`gate-lib.py` themselves —
  reference only, per "자체 재구현 금지."
- `partnerships-bd/hooks/record-fields.config` and the role-level gates
  (core canon, not this repo's gates) — not named in issue #10's audit.
- Actual code changes to the 5 gate scripts, README, and tests — phase-2
  execution, opens only on an approvers.md Approve.
