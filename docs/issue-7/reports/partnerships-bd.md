# Record — issue-7 (partnerships-bd)

loop_state: decided

Subject: issue-7. Phase 2 — executes the approved proposal
`docs/issue-7/proposals/methodology-plugin-set.md` (human Approve:
issue comment `APPROVE issue-7/partnerships-bd`).

## What was done

Built the five methodology plugins named in the proposal's plugin list,
each a self-contained sibling of `partnerships-bd/` at repo root
(own `.claude-plugin/plugin.json`, `hooks/hooks.json`, `hooks/directive.sh`,
one fail-closed PreToolUse gate script, own repo-root `tests/*-tests.sh`
suite):

- `strategic-fit-gate/` — ICP-fit + compounding-value opening test,
  phase-1 only, denies before a scoring table if the fit/compounding-value
  statement is missing or comes after the table.
- `multi-axis-scoring/` — weighted 6-axis evaluation table (canonical
  list in `multi-axis-scoring/reference/axes.md`), both phases.
- `batna-zopa/` — explicit BATNA statement, ZOPA required only when
  counterpart-position language is present, both phases.
- `evidence-discipline/` — stage declaration (non-binding vs
  binding-terms-ready) + citation presence, phase-1 only.
- `term-sheet-structure/` — 7-subsection term-sheet norm, phase-2 only,
  exit/termination non-optional, governance/KPIs kept distinct.

Registered all 5 in `.claude-plugin/marketplace.json` as new sibling
entries alongside the existing `partnerships-bd` entry. Added
`tests/parse-check.sh` and `tests/deny-only-check.sh` (copied verbatim
per this rulebook family's own convention — these two are explicitly
meant to be copied, unlike gate logic) and a new `tests/run-gate-tests.sh`
dispatcher over the 5 plugin suites. All 46 gate-test assertions pass
(9+8+10+9+10); `parse-check.sh` passes bash-3.2 parsing on all 19 shell
files; `deny-only-check.sh`'s grep scan finds no `permissionDecision:
allow` anywhere and its broadened substance probe confirms at least one
gate refuses an empty write on both the proposal and record surfaces.
Updated root `README.md` with a "Methodology plugins" section and the
run-the-checks snippet. Canon scripts referenced only (core's
`role-directive.sh` lib), never copied; no plugin here gained a `src/`
write scope (`WRITE_SCOPE: []` unchanged); existing `partnerships-bd`
plugin's own directive/gate config untouched.

## Why

The maturation round (issue-1) fixed five methodologies only as prose in
`partnerships-bd/reference/deliverable-shapes.md` — none mechanically
enforced. Issue-7's requirement-correction comment specified a plugin
*set*, one independent self-contained plugin per methodology (freelunch/
scout-level completeness), not a single gate. Basis: the approved
proposal's plugin table and its two derived phase-combination rules
((b) phase-1 = strategic-fit-gate -> multi-axis-scoring -> batna-zopa ->
evidence-discipline; (c) phase-2 = multi-axis-scoring + batna-zopa +
term-sheet-structure).

## deal-structure-verdict

Weighted multi-axis evaluation of *this delivery itself* against the
approved proposal (self-referential verdict: did the phase-2 build match
the phase-1 shape it committed to) — not a live partner deal, since this
issue is a tooling round on the role's own gate machinery. All 6 axes,
weight + score:

| Axis | Weight | Score (0-10) | Note |
|---|---|---|---|
| strategic/ICP fit | 0.20 | 9 | Directly serves the role's own USE_WHEN; no scope creep beyond the 5 named methodologies. |
| financial health | 0.10 | 8 | Zero new infra cost — bash + python3 only, same as sibling rulebooks. |
| legal/compliance posture | 0.20 | 9 | Canon-scripts.md honored (lib referenced, not vendored); WRITE_SCOPE unchanged. |
| operational capability | 0.20 | 9 | 46/46 gate-test assertions pass; fail-closed on crash/malformed input verified per plugin. |
| cultural fit | 0.10 | 8 | Matches the exact sibling-plugin shape already proven in product-discovery and pricing rulebooks. |
| compounding-value | 0.20 | 9 | Future issues on this role inherit 5 working enforcement points instead of prose-only guidance. |

Sum (weighted): 8.7/10 — proceed, no residual blocker.

**BATNA**: the proposer's (this role's) own walk-away alternative was a
single combined `methodology-gate.sh` on the role's two write surfaces,
mirroring pricing-rulebook's original shape before its own plugin split
— rejected per the issue's explicit requirement correction for
independent per-methodology plugins, but named here as the real
fallback if a future round needs to collapse the set back down for
maintenance-cost reasons.

**ZOPA**: not estimated — no external counterpart in this delivery (the
"counterpart" here is the human approver, who already fixed the
required shape in the requirement-correction comment and Approved this
exact plan; no negotiation range remains open).

## term-sheet-outline

Not applicable — this issue does not produce a partnership term sheet
(it builds the plugin machinery that will gate a future one). The
`term-sheet-structure` plugin itself is the phase-2 deliverable for
that future field; see its `hooks/term-sheet-structure-gate.sh` for the
7-subsection enforcement (purpose, roles & responsibilities, terms,
governance, KPIs, dispute resolution, exit/termination — exit
non-optional, governance and KPIs never merged).

## Open findings

None. All 46 gate-test assertions pass, `parse-check.sh` and
`deny-only-check.sh` both pass, `marketplace.json` is valid JSON with 6
entries. The one open assumption carried over from issue-1/issue-2
(core's exact per-role sub-section-gate-read convention, see
`docs/issue-1/reports/partnerships-bd/survey.md` and this issue's own
`docs/issue-7/reports/partnerships-bd/survey.md`) remains unconfirmed —
this round's gates are this role's own enforcement, independent of
whatever core's promoted gate eventually reads, so the assumption does
not block this delivery.

## Next-steps

None required to close this issue. Optional future work, not blocking:
confirm core's exact sub-section-gate-read convention (open assumption
above) and, if core ships one, migrate `REQUIRED_SUBSECTIONS_*` out of
`partnerships-bd/hooks/record-fields.config` to match it.

## Open-finding-resolution-path

No open finding to resolve — see "Open findings" above; the one
carried-over assumption is non-blocking and has no resolution deadline
tied to this issue.

## Hand-off

None open. Boundary unchanged: legal/contract review still hands off to
`legal-compliance` per the role directive; this issue only strengthens
this role's own gate machinery, it does not touch that hand-off arrow.
