# issue-16 current-state survey

## Scope of the check
`roles/specs/partnerships-bd.spec.json` (on-the-record) is not vendored in
this repo and was not found anywhere on disk (`find / -iname
partnerships-bd.spec.json` — no hits). The issue body itself states the
spec's required fields (`partner_id`, `lifecycle_stage`, `governance_note`)
and loop_state vocabulary (`assessing, collaborating, landed,
partner-unreachable, stage-undeclared`) verbatim, so this survey works from
that text as the spec source of truth rather than reading the file.

## Scout skip record
Skip condition applied: **spec leaves no design decision open** for the
scout protocol's product-benchmarking sense — the three field names and
five loop_state values are fixed externally by the marketplace spec: there
is no competing external product/category to benchmark against, only an
internal mapping-onto-existing-docs decision. No web/product scouting run.

## Write-surface inventory (what exists today, per spec field)

### `partner_id`
No existing rulebook doc or hook names a partner identifier field. Neither
`partnerships-bd/reference/deliverable-shapes.md` (deal-structure-verdict,
term-sheet-outline shapes) nor `partnerships-bd/hooks/record-fields.config`
(`REQUIRED_FIELDS="deal-structure-verdict,term-sheet-outline"`) has a slot
for it. No natural home currently exists; this is a genuine gap the
proposal must address explicitly (issue's "empty state" clause).

### `lifecycle_stage`
Partial existing hook: `deliverable-shapes.md` lines 34-39 ("Phase-1
proposal convention") already requires phase-1 docs to "declare stage
(non-binding vs binding-terms-ready)" — a two-value staging concept, but
undocumented as a first-class required record field, not present in
`record-fields.config`'s `REQUIRED_FIELDS`, and not gated (the doc says so
explicitly: "No phase-1 gate exists yet; enforced by human PR review").
This is the closest match to `lifecycle_stage` — needs strengthening into
a named required field, not literal renaming (the doc already flags this
as "documented only, no gate yet").

### `governance_note`
`deliverable-shapes.md`'s term-sheet-outline shape already names a
"governance — decision-making authority thresholds (kept distinct from
KPIs)" sub-section (item 4 of 7), gated via
`record-fields.config`'s `REQUIRED_SUBSECTIONS_term_sheet_outline`
(includes `governance`). This existing sub-section is the governance
concept's current home, but it is scoped as a nested piece of
term-sheet-outline, not a standalone top-level record field the way the
spec's `governance_note` is worded. Gap between "existing nested
sub-section" and "spec top-level field" needs the proposal to state
whether it strengthens the existing sub-section in place or adds an
explicit top-level field, and why.

### loop_state vocabulary
Grep across all four prior partnerships-bd phase-1/phase-2 records shows
inconsistent ad-hoc terminal values in actual use:
- `docs/issue-1/reports/partnerships-bd.md:45` → `loop_state: done`
- `docs/issue-7/reports/partnerships-bd.md:3` → `loop_state: decided`
- `docs/issue-10/reports/partnerships-bd.md:39` → `loop_state: done`
- `docs/issue-13/reports/partnerships-bd.md:65` → `loop_state: landed`

No repo-local `docs/specs/record-fields-terminal-states.json` override
exists (`find -iname '*terminal-states*'` — no hits); this role currently
inherits core canon's global per-kind terminal-state list unmodified. The
spec's five-value vocabulary (`assessing, collaborating, landed,
partner-unreachable, stage-undeclared`) does not match any of the four
values actually used (`done`, `decided`, `landed` — only `landed`
overlaps). This is the field with the clearest and most mechanical fix:
add a role-local override file naming exactly the spec's five values,
which also resolves the drift already visible across issue-1/7/10/13.

## Files expected to change (frozen write set for the proposal)
- `partnerships-bd/reference/deliverable-shapes.md` — add `partner_id` and
  `governance_note` field definitions; formalize `lifecycle_stage`.
- `partnerships-bd/hooks/record-fields.config` — extend `REQUIRED_FIELDS`.
- `docs/specs/record-fields-terminal-states.json` — new file, role-local
  loop_state vocabulary override (contract v3's named override mechanism).
- `README.md` — sync the `produces` line and any field-list summary.
- `docs/issue-16/proposals/spec-alignment.md` — this proposal itself.

No hook script (`.sh`) logic change is anticipated: `record-fields.config`
is data read by core canon's gate, not new gate code, and no existing test
in `tests/*.sh` asserts on these three field names or the loop_state set,
so no test-file edits are expected either (confirmed by grepping
`tests/*.sh` for the three field names and the five vocabulary words — no
hits).
