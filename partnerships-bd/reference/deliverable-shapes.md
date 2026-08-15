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
- **strategic/ICP fit axis: name the partner tier, not just a fit
  score.** State which tier the counterpart falls in (e.g. strategic /
  preferred / transactional) and what that tier changes about the deal
  — resourcing depth, exclusivity terms, review cadence. A fit score
  with no tier collapses "worth doing" and "worth doing at this depth"
  into one number; the tier is what a reviewer needs to sanity-check the
  weight actually assigned.
- **Gate the tier claim on independent-demand evidence before scoring
  it.** Before the strategic/ICP-fit axis is scored at all, name the
  evidence that the counterpart brings independent demand (named
  accounts they can point to, an end-customer relationship, a sales
  motion of their own) as distinct from a counterpart chasing
  preferential terms with no demand of their own. If that evidence
  cannot be honestly stated, the axis score is not yet defensible —
  stop and get the evidence before scoring, rather than scoring a
  guess.
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
   marketplace spec's `governance_note` required field (issue-16).
   Name the approval-embedding point explicitly: which existing,
   already-adopted workflow surface (the counterpart's own deal review
   channel, not a new standalone portal) each threshold's approval
   actually routes through. A threshold with no named routing point is
   an authority claim nobody will act on when the deal is live. Each
   threshold names a specific human approver, never "approved" as a
   bare state — the verdict this role hands up is always a recommendation
   plus a named approver, not an auto-approval. A single
   deal-killing risk signal (e.g. uncapped indemnity, no data-processing
   terms, unlimited exclusivity with no minimums) overrides an otherwise
   high composite score and forces escalation regardless of the
   weighted-axis total — do not let a strong multi-axis score wave
   through a term that is disqualifying on its own.
5. KPIs/success metrics — measurable, accountability-bearing
6. dispute resolution mechanism
7. exit/termination clause — conditions, notice periods, wind-down
   obligations (non-optional). State the cure period length for each
   named breach condition and the post-termination handling of shared
   data/IP explicitly — a notice period with no cure window or with
   data/IP handling left implicit is not a wind-down obligation a
   counterpart can actually execute against. Write the unwind
   trigger conditions (the measurable thresholds — e.g. missed
   volume commitment for N consecutive periods, named-account
   sourcing falling to zero — that justify exercising this clause)
   directly into this sub-section at deal-signing time, not left for
   a future review to improvise: an exit clause with no pre-agreed
   trigger makes the unwind a fresh negotiation instead of a
   mechanical exercise of an already-agreed right.

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

This vocabulary is documented here as prose convention, not enforced via
`docs/specs/record-fields-terminal-states.json`: that override mechanism
(core canon, contract v3 §2) accepts only the fixed nine contract record
kinds (`coding-record`, `feasibility-record`, `ops-record`,
`product-record`, `qa-record`, `reflect-record`, `review-record`,
`ux-design-record`, `verify-record`) — confirmed at build time by
`record-fields-gate.sh` refusing both `partnerships-bd` and
`partnerships-bd-record` as unrecognized kinds. `partnerships-bd` is not
one of those nine, so no terminal-states override exists for it; human
PR review is what enforces this vocabulary until core adds such a kind.

## Phase-1 proposal convention (documented only, no gate yet)

Phase-1 proposal docs for this role should additionally open with a
strategic-fit statement, declare stage (non-binding vs
binding-terms-ready), and cite evidence per claim — see proposal item
(d)(5). No phase-1 gate exists yet; enforced by human PR review.
