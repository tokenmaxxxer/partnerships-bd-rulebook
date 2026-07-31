# Current-state survey — partnerships-bd rulebook (issue-1)

Subject: issue-1 phase 1. What exists today for the partnerships-bd role
in this repo, and what's missing relative to
`docs/issue-1/reports/partnerships-bd/scout-brief.md`.

## What exists

- `partnerships-bd/.claude-plugin/plugin.json` — plugin manifest; its
  `description` restates the directive one-liner (`decides`/`use_when`/
  `hand-off`).
- `partnerships-bd/hooks/directive.sh` — post issue-2 conversion (core
  canon reference, `docs/issue-2/proposals/core-canon-conversion.md`
  item 3). Sources `core/hooks/lib/role-directive.sh`, calls
  `core_role_directive` with four role-unique strings: `YOU_DECIDE`
  ("파트너십이 구조적으로 성립하는가"), `USE_WHEN` ("제휴/BD 딜 구조가
  걸릴 때"), `PRODUCES` ("deal structure verdict, term sheet outline" +
  `WRITE_SCOPE: []`), `HAND_OFF` ("법적 계약 검토는 → legal-compliance"
  + the generic boundary-case reminder). No methodology content — the
  strings name *what* is produced, not *how* it must be derived.
- `partnerships-bd/hooks/record-fields.config` — declares
  `REQUIRED_FIELDS="deal-structure-verdict,term-sheet-outline"` as a
  per-role override for core's promoted `record-fields-gate.sh` (core
  issue #66). Explicitly flagged in its own header as carrying an
  unverified assumption about core's config-read convention, to be
  confirmed in a future phase 2 (issue-2's, not this issue's).
  Enforces field *presence* only, not field *content*.
- `partnerships-bd/agents/warrant-hunter.md` — post issue-2 conversion,
  now a thin core-canon reference. Retains this role's decision
  boundary and hand-off line; explicitly notes its stance rotation set
  is still an unresolved skeleton gap (pre-existing, not this issue's
  scope).
- `partnerships-bd/hooks/hooks.json` — registers only `directive.sh` on
  `SessionStart`; the three role-agnostic gates were dropped from this
  file by issue-2 (core's own registration covers them per core issue
  #66).
- `docs/specs/approvers.md` — names the human-approval mechanism
  (GitHub PR review Approve, or single-account-mode issue comment
  `APPROVE issue-<n>/<role>`) that gates phase 2 per contract v3 s19.
  Not partnerships-bd-specific, but is the mechanism this issue's own
  phase 2 will need.
- `docs/issue-2/` — prior issue's full phase-1+phase-2 trail (survey,
  proposal, and `docs/issue-2/reports/implementation.md` record),
  useful as a structural template for this issue's own docs, though its
  subject (core-canon reference conversion) is unrelated to rulebook
  maturation content.

## What's missing / thin relative to the scout brief

- **No stated evaluation methodology.** Nothing in `directive.sh`,
  `plugin.json`, or `warrant-hunter.md` names a strategic-fit/ICP-fit
  gate, a weighted multi-axis due-diligence scoring approach, or a
  BATNA/ZOPA deal-structuring frame. The `deal-structure-verdict`
  required field currently has no required *derivation method* behind
  it — an agent (or human) could write any string and satisfy the
  field-presence gate.
- **No required-sections/citation-format spec for phase-1 proposal
  docs from this role.** Nothing says a partnerships-bd phase-1
  proposal must cite sources, distinguish LOI/MOU-stage framing from
  binding terms, or state a BATNA/walk-away position.
- **`term-sheet-outline` has no required component list.** The scout
  brief's phase-2 must-bes (governance section distinct from KPIs, exit
  clause, dispute resolution, decision-rights thresholds) are not named
  anywhere as required sub-fields or sub-sections of that one required
  field — it is currently a single free-text field name with no shape
  contract.
- **No gate checks the *content* of either required field**, only their
  presence (`record-fields.config` checks `REQUIRED_FIELDS` exist;
  nothing checks that `term-sheet-outline` contains a governance
  sub-section, an exit clause, etc.).
- **No plugin-level scoring/rubric artifact.** There is no file in
  `partnerships-bd/` analogous to a rubric or weighted-criteria
  reference that a hunt-agent or phase-2 author would consult.

This gap is exactly what
`docs/issue-1/proposals/rulebook-maturation.md` proposes to close.
