# Proposal — partnerships-bd rulebook maturation (issue-1, phase 1)

Subject: issue-1. Phase 1 proposal only — describes the phase-2 change,
does not execute it. Based on
`docs/issue-1/reports/partnerships-bd/scout-brief.md` and
`docs/issue-1/reports/partnerships-bd/survey.md`.

## (a) Phase-1 proposal norms to adopt

Future partnerships-bd phase-1 proposal docs in this repo must:

1. **Open with a strategic-fit/ICP-fit statement** before any
   financial/legal/operational analysis — name the candidate partner's
   ICP overlap with the proposer's own ICP and the compounding-value
   test (does the combination solve something neither side solves
   alone), before scoring anything else.
2. **Carry a weighted multi-axis evaluation table**, not a prose verdict:
   at minimum the axes strategic/ICP fit, financial health, legal/
   compliance posture, operational capability, cultural fit, and
   compounding-value, each with an explicit weight and score, summing to
   the `deal-structure-verdict`.
3. **State a BATNA and, where a counterpart position is known, a ZOPA
   estimate** — the proposer's own walk-away alternative, named
   explicitly, not implied.
4. **Declare the proposal's stage**: non-binding (LOI/MOU-equivalent
   framing) vs binding-terms-ready, so downstream readers know how much
   weight the document's language carries.
5. **Cite evidence per claim**: framework/methodology claims cite a
   named source (URL or canonical text); factual claims about a specific
   candidate partner cite primary evidence (data-sharing tool output,
   financial statement, reference call note) — bare assertion is not
   acceptable for either category.

## (b) Phase-2 deliverable norms to adopt

Future partnerships-bd phase-2 outputs (the role's record file,
`docs/issue-<n>/reports/partnerships-bd.md`) must expand the existing
two required fields into required *shapes*:

- **`deal-structure-verdict`** must show the weighted multi-axis score
  from (a)(2) and the BATNA/ZOPA statement from (a)(3) as its
  derivation — not just a final yes/no/score.
- **`term-sheet-outline`** must contain, as named sub-sections:
  - purpose/scope of the partnership
  - roles & responsibilities of each party
  - value/profit-sharing or capital-contribution terms
  - **governance**: decision-making authority thresholds (kept as its
    own sub-section, distinct from KPIs — the scout brief's must-be)
  - **KPIs/success metrics**: measurable, accountability-bearing
  - dispute resolution mechanism
  - **exit/termination clause**: conditions, notice periods, wind-down
    obligations (non-optional — named failure mode if absent)

## (c) Rationale, tied to the scout brief

- **Strategic-fit-first ordering (a.1)** exists because the scout
  brief's must-be states strategic misalignment survives even a clean
  financial/legal review — sequencing the proposal any other way lets a
  wrong-partner deal pass early gates on the wrong criteria. This
  directly targets the survey's gap line: "no stated evaluation
  methodology... an agent could write any string and satisfy the
  field-presence gate."
- **Weighted multi-axis table (a.2)** is the scout brief's "adopt"
  pattern — it converts `deal-structure-verdict` from an assertable
  string into an auditable derivation, closing the survey's finding that
  the required field currently has no required derivation method behind
  it.
- **BATNA/ZOPA (a.3)** is adopted because it is the field-tested
  standard for deal-structuring logic (Harvard PON literature) and this
  role's own directive already frames its mandate as "파트너십이
  구조적으로 성립하는가" (does the partnership structurally hold) —
  BATNA is precisely the test of whether walking away is better than the
  proposed structure, i.e., the same question in negotiation-theory
  terms. Deliberately not adopting a full JV-specific 8-area diligence
  checklist (scout brief's "skip" pattern) because this role has not
  committed to any single deal type, and importing a fixed area list
  would over-fit the required fields to one deal shape.
- **Stage declaration (a.4) and citation format (a.5)** close the
  survey's "no required-sections/citation-format spec" gap directly —
  without them, a phase-1 doc's claims are unfalsifiable and its
  bindingness is ambiguous to a downstream legal-compliance hand-off.
- **Governance as its own sub-section, separate from KPIs (b)** is
  adopted verbatim from the scout brief's must-be (the literature names
  these as two distinct critical-success factors, not one) — collapsing
  them risks a term sheet that states metrics with no decision-rights
  model behind them, which the survey found is exactly what the current
  single free-text `term-sheet-outline` field permits.
- **Exit clause as non-optional (b)** is adopted because its absence is
  named directly in the scout brief as a recurring dispute-driving
  failure mode; making it a required sub-section is the cheapest gate
  against that known failure.

## (d) Plugin reflection plan

Concrete phase-2 changes (not executed here) to the plugin files
surveyed in `docs/issue-1/reports/partnerships-bd/survey.md`:

1. **`partnerships-bd/hooks/directive.sh`** — extend the `PRODUCES`
   heredoc string to name the required shape, not just the two field
   names, e.g. append a short reference: `deal-structure-verdict (must
   show weighted multi-axis score + BATNA/ZOPA), term sheet outline
   (must contain: purpose, roles, terms, governance, KPIs, dispute
   resolution, exit clause)`. Keep this a one-line pointer in the
   directive string (directive strings are meant to stay short); the
   full shape spec lives in a new reference file (next item).

2. **New file: `partnerships-bd/reference/deliverable-shapes.md`** (new
   directory under the plugin, alongside existing `agents/` and
   `hooks/`) — the canonical, machine-checkable list of required
   sub-sections for `term-sheet-outline` and the required derivation
   components for `deal-structure-verdict`, as fixed in this proposal's
   parts (a) and (b). `directive.sh` and any future gate script both
   point to this file rather than duplicating the list inline.

3. **`partnerships-bd/hooks/record-fields.config`** — currently checks
   only field *presence*. Phase 2 should add, alongside the existing
   `REQUIRED_FIELDS` line, a `REQUIRED_SUBSECTIONS` (or equivalent,
   depending on what core's promoted `record-fields-gate.sh` actually
   supports — per the file's own open assumption flag) mapping
   `term-sheet-outline` to the seven sub-section names in part (b), so
   the gate can fail a record whose `term-sheet-outline` is present but
   missing e.g. an exit clause. This is new gate surface, not present in
   core's current per-role config convention as inspected in issue-2's
   survey — phase-2 implementer must confirm core's gate script actually
   reads a sub-section-level check before wiring this, and fall back to
   a phase-1-doc-side review checklist if core's gate has no such hook.

4. **`docs/issue-1/reports/partnerships-bd.md` (future phase-2 record,
   not created by this issue's phase 1)** — once phase 2 opens, its
   frontmatter/required fields must match whatever `record-fields.config`
   enforces per item 3, and its body must follow the sub-section list in
   `deliverable-shapes.md`.

5. **Phase-1 proposal docs template** — no plugin file currently governs
   phase-1 proposal *shape* (only phase-2 record shape has a gate). If a
   future role-agnostic "phase-1 doc gate" exists in core (none found in
   this tree per the survey), this role's config for it should require:
   evaluation-table presence, BATNA/ZOPA statement presence, stage
   declaration, and a non-empty citations/sources list — mirroring parts
   (a.1)-(a.5). If no such core gate exists, this remains a documented
   convention (this proposal) enforced by human PR review until core
   ships one.

## Out of scope for this proposal

- Executing any of the above file changes (phase 2, gated on human
  Approve per `docs/specs/approvers.md` / contract v3 s19).
- Resolving the warrant-hunter stance rotation gap (pre-existing,
  unrelated to this issue).
- Confirming core's exact per-role gate config-read convention (flagged
  as an open assumption in issue-2's own artifacts; phase-2 implementer's
  job, not this proposal's).
