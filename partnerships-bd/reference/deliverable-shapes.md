# Deliverable shapes — partnerships-bd

Canonical required-shape spec for this role's two required record
fields. `directive.sh` and any future gate script point here rather
than duplicating this list inline. Fixed by
`docs/issue-1/proposals/rulebook-maturation.md` parts (a) and (b).

## deal-structure-verdict

Must show its derivation, not just a final yes/no/score:

- **Weighted multi-axis evaluation table** — axes: strategic/ICP fit,
  financial health, legal/compliance posture, operational capability,
  cultural fit, compounding-value. Each axis carries an explicit weight
  and score; the scores sum to the verdict.
- **BATNA statement** — the proposer's own walk-away alternative,
  named explicitly, not implied.
- **ZOPA estimate** — where a counterpart position is known.

## term-sheet-outline

Must contain these named sub-sections, in this order:

1. purpose/scope of the partnership
2. roles & responsibilities of each party
3. value/profit-sharing or capital-contribution terms
4. governance — decision-making authority thresholds (kept distinct
   from KPIs) — this sub-section is this role's home for the
   marketplace spec's `governance_note` required field (issue-16)
5. KPIs/success metrics — measurable, accountability-bearing
6. dispute resolution mechanism
7. exit/termination clause — conditions, notice periods, wind-down
   obligations (non-optional)

## partner_id

Required top-level record field (marketplace spec, issue-16): the
counterpart org/individual identifier every partnerships-bd record must
carry. State it plainly — legal entity name or equivalent identifier —
at the top of the record, alongside the deal-structure-verdict.

## lifecycle_stage

Required top-level record field (marketplace spec, issue-16), replacing
the prior two-value non-binding/binding-terms-ready description below
with the spec's five-value vocabulary (shared with `loop_state`, since
deal lifecycle and loop_state are the same underlying progression for
this role):

- `assessing`
- `collaborating`
- `landed`
- `partner-unreachable`
- `stage-undeclared`

## Phase-1 proposal convention (documented only, no gate yet)

Phase-1 proposal docs for this role should additionally open with a
strategic-fit statement, declare stage (non-binding vs
binding-terms-ready), and cite evidence per claim — see proposal item
(d)(5). No phase-1 gate exists yet; enforced by human PR review.
