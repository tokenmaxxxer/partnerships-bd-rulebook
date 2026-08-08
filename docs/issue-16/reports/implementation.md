---
code_under_review: PENDING
type: doc
breaking: false
verdict: pending
loop_state: coding
---

# issue-16 phase 2: spec-alignment implementation

## Summary of work

Applied `docs/issue-16/proposals/spec-alignment.md` verbatim: layered the
`partnerships-bd` marketplace spec's three required fields (`partner_id`,
`lifecycle_stage`, `governance_note`) and five-value `loop_state`
vocabulary onto the rulebook.

- `partnerships-bd/reference/deliverable-shapes.md`: added `## partner_id`
  and `## lifecycle_stage` sections; added a governance_note cross-reference
  line to the existing term-sheet-outline governance sub-section.
- `partnerships-bd/hooks/record-fields.config`: extended `REQUIRED_FIELDS`
  to `"deal-structure-verdict,term-sheet-outline,partner-id,lifecycle-stage"`.
- `docs/specs/record-fields-terminal-states.json` (new): `partnerships-bd`
  kind entry with the spec's exact five loop_state values.
- `README.md`: synced `produces` line and Methodology plugins lead-in to
  name the three spec fields.

## Why

Basis: `docs/issue-16/proposals/spec-alignment.md` (approved via issue
comment `APPROVE issue-16/implementation`, single-account mode,
`JiwonJung94` listed in `docs/specs/approvers.md`). Rationale for each
choice (governance_note nested vs top-level; terminal-states override vs
prose) is recorded in the proposal's own Rationale section — not repeated
here.

## Upstream

Based on: docs/issue-16/proposals/spec-alignment.md

## What did not work

None.

## Open findings

None.

## Next steps

Commit, push, open PR with `Closes #16`; update `code_under_review`/
`verdict`/`loop_state` to `landed` once commit sha is known.

## Resolution path

N/A — no open findings.
