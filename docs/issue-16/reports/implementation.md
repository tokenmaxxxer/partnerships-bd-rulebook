---
code_under_review:
  - README.md
  - partnerships-bd/hooks/record-fields.config
  - partnerships-bd/reference/deliverable-shapes.md
  - docs/issue-16/reports/implementation.md
type: doc
breaking: false
verdict: pass
loop_state: landed
---

# issue-16 phase 2: spec-alignment implementation

## Summary of work

Applied `docs/issue-16/proposals/spec-alignment.md`: layered the
`partnerships-bd` marketplace spec's three required fields (`partner_id`,
`lifecycle_stage`, `governance_note`) and five-value `loop_state`
vocabulary onto the rulebook.

- `partnerships-bd/reference/deliverable-shapes.md`: added `## partner_id`
  and `## lifecycle_stage` sections; added a `governance_note`
  cross-reference line to the existing term-sheet-outline governance
  sub-section; documented the five-value vocabulary as prose (see
  deviation below).
- `partnerships-bd/hooks/record-fields.config`: extended `REQUIRED_FIELDS`
  to `"deal-structure-verdict,term-sheet-outline,partner-id,lifecycle-stage"`.
- `README.md`: synced `produces` line and Methodology plugins lead-in to
  name the three spec fields.
- Proposal step 3 (`docs/specs/record-fields-terminal-states.json`) was
  attempted and reverted — see `## Rationale for deviations`.

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

- Wrote `docs/specs/record-fields-terminal-states.json` with a
  `partnerships-bd` kind entry per proposal step 3 — `record-fields-gate.sh`
  refused it: the override mechanism accepts only contract §2's fixed nine
  record kinds (`coding-record`, `feasibility-record`, `ops-record`,
  `product-record`, `qa-record`, `reflect-record`, `review-record`,
  `ux-design-record`, `verify-record`). Tried renaming the key to
  `partnerships-bd-record` — also refused, same closed-vocabulary reason.
  Reverted the file entirely (`git rm`).

## Rationale for deviations

Proposal step 3 assumed `record-fields-terminal-states.json` accepts an
arbitrary role-named kind key. At build time `record-fields-gate.sh`
enforces a closed vocabulary of nine contract-defined kinds, none of
which is `partnerships-bd`. This was not discoverable from the proposal's
survey (the survey inspected the mechanism's existence and JSON shape,
not the gate's kind allowlist). Since the mechanism cannot express this
role's vocabulary, the file was reverted and the five-value
`lifecycle_stage`/`loop_state` vocabulary is documented as prose in
`deliverable-shapes.md` instead — the fallback the proposal's own
Rationale section had already named and rejected only because the
mechanical route seemed available; it is not. Human PR review enforces
the vocabulary until core adds a kind for this role. All other proposal
steps (1, 2, 4) applied as written, no other deviation.

## Open findings

None.

## Next steps

None — record is terminal (`loop_state: landed`).

## Resolution path

N/A — no open findings.
