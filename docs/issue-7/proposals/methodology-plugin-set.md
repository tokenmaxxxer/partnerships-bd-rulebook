# Proposal — partnerships-bd methodology plugin set (issue-7, phase 1)

Subject: issue-7. Phase 1 proposal only — describes the phase-2 change,
does not execute it. Based on
`docs/issue-7/reports/partnerships-bd/survey.md` and
`docs/issue-7/reports/partnerships-bd/scout-brief.md`. Written to the
issue's requirement-correction comment: a **plugin set**, not a single
gate/directive — one independent, self-contained plugin per adopted
methodology, phase-1 and phase-2 norms each expressed as a stated
combination of that set.

Stage: binding-terms-ready for the plugin *shapes and gate logic*
described below; not binding on exact script line counts (implementer's
call within the shape). Evidence: every methodology claim below cites
the issue-1 adoption doc it derives from; every structural-pattern claim
cites the sibling-rulebook exemplar file read in the scout brief.

## (a) Plugin list — required per issue's "요구 정정" comment

Five plugins, one methodology each, all siblings of the existing
`partnerships-bd` role plugin inside this same marketplace (pattern:
`~/tokenmaxxxer/rulebooks/implementation-rulebook/.claude-plugin/marketplace.json`,
which lists `coding` + 3 companion methodology plugins — read in scout
stage 1). Each plugin below is self-contained per that exemplar's shape:
own `.claude-plugin/plugin.json`, own `hooks/`, gate scripts using the
pricing-rulebook `methodology-gate.sh` fail-closed pattern (scout stage
1) scoped by regex to this role's own write surfaces, never core's
canon files (canon-scripts.md compliant — reference core's
`role-directive.sh` lib, never vendor it).

| Plugin | Methodology owned | Components | Combination role |
|---|---|---|---|
| `strategic-fit-gate` | ICP-fit + compounding-value opening test (adoption doc (a).1) | `hooks/directive.sh` (steers: open every proposal with strategic-fit/ICP-overlap/compounding-value before any scoring); `hooks/gate.sh` (PreToolUse on `docs/issue-<n>/proposals/*partnerships*.md`, fail-closed, denies a proposal write with no ICP-fit/compounding-value language before its first scoring table) | **Phase-1 only** — first gate in the phase-1 combination (ordering: this plugin's gate must pass before content downstream of it is scored, per adoption doc's sequencing rationale) |
| `multi-axis-scoring` | Weighted multi-axis evaluation table (adoption doc (a).2, (b) verdict derivation) | `hooks/directive.sh` (steers: 6 named axes, explicit weight+score per axis, summing to verdict); `hooks/gate.sh` (fail-closed check that all 6 axis names + weight/score pairs appear, on both proposal and record write surfaces); `reference/axes.md` (canonical 6-axis list, single source so the gate and the directive point to the same list instead of duplicating it) | **Both phases** — same methodology derives both the phase-1 proposal's evaluation table and the phase-2 record's `deal-structure-verdict` derivation |
| `batna-zopa` | BATNA statement + ZOPA estimate (adoption doc (a).3, (b) verdict derivation) | `hooks/directive.sh` (steers: name the proposer's own walk-away alternative explicitly; estimate ZOPA when counterpart position is known); `hooks/gate.sh` (fail-closed check for explicit BATNA language, ZOPA checked only when counterpart-position language is present — mirrors pricing-gate's conditional-check pattern) | **Both phases** — negotiation-theory derivation shared by proposal and record |
| `evidence-discipline` | Stage declaration + citation-per-claim (adoption doc (a).4, (a).5) | `hooks/directive.sh` (steers: declare non-binding vs binding-terms-ready; cite a source per framework claim and per factual candidate-partner claim); `hooks/gate.sh` (fail-closed check for a stage-declaration token and a non-empty citation/source list) | **Phase-1 only** — this is a proposal-rigor methodology; the phase-2 record does not re-declare stage or re-cite framework claims |
| `term-sheet-structure` | 7-subsection term-sheet norm (adoption doc (b), exit clause non-optional, governance/KPIs kept distinct) | `hooks/directive.sh` (steers: emit all 7 named sub-sections in order); `hooks/gate.sh` (fail-closed check for all 7 sub-section headers on the record write surface only; denies specifically when exit/termination is the missing one, per adoption doc's named failure mode); `hooks/tests/` (gate test cases, item (c) below) | **Phase-2 only** — `term-sheet-outline` is a phase-2-record-only field; no phase-1 proposal carries a term sheet |

Existing `partnerships-bd` plugin is retained as the 6th, unchanged
core-role plugin (directive/YOU_DECIDE/USE_WHEN/HAND_OFF, agents/
warrant-hunter.md) — it is the role identity, not a methodology, so it
stays outside this set per the issue's own framing ("채택 방법론 각각을
독립 플러그인으로").

## (b) Phase-1 proposal norm = plugin combination

A phase-1 proposal doc for this role is governed by, in this fixed
order: `strategic-fit-gate` → `multi-axis-scoring` (proposal-side table)
→ `batna-zopa` (proposal-side statement) → `evidence-discipline`. The
combination, not any single plugin, is what "phase-1 proposal norm"
means going forward — a proposal that passes 3 of 4 gates is not a
compliant phase-1 doc. Sequencing matters: `strategic-fit-gate` denies
before the scoring-table gates run their own check, per the adoption
doc's rationale that a wrong-partner deal must not clear the door on
financial/legal criteria alone.

## (c) Phase-2 record norm = plugin combination

The phase-2 record (`docs/issue-<n>/reports/partnerships-bd.md`) is
governed by: `multi-axis-scoring` (record-side, feeds
`deal-structure-verdict`) + `batna-zopa` (record-side) +
`term-sheet-structure` (feeds `term-sheet-outline`). `evidence-discipline`
and `strategic-fit-gate` do not re-fire on phase-2 — those are
proposal-stage rigor, already satisfied upstream per the adoption doc's
own field-vs-derivation split (deal-structure-verdict's derivation is
multi-axis+BATNA/ZOPA; term-sheet-outline's derivation is the
sub-section structure — neither field's derivation includes stage
declaration or citations).

## (d) Gate tests (repo-root `tests/`, per issue requirement 3)

One pass-case and one deny-case file per plugin gate (10 files total):
e.g. `tests/strategic-fit-gate-pass.md`, `tests/strategic-fit-gate-deny.md`,
mirroring the pricing-rulebook + no-footgun test-fixture convention read
in scout stage 1 (fixture files fed to the gate script directly, not
through a live Claude session).

## (e) marketplace.json change (phase 2, not executed here)

Repo-root `.claude-plugin/marketplace.json` gains 5 new entries
(sources `./strategic-fit-gate`, `./multi-axis-scoring`, `./batna-zopa`,
`./evidence-discipline`, `./term-sheet-structure`), each `description`
naming its one methodology and cross-referencing this set by name —
same pattern as implementation-rulebook's `coding` entry naming its
three companions.

## Out of scope for this proposal (phase 2, gated on human Approve)

- Writing any plugin.json/hooks.json/gate.sh/test file listed above.
- Editing `marketplace.json`.
- Retiring or editing the existing `partnerships-bd` plugin's own
  directive/gate config (unchanged by this proposal).
- Confirming core's exact per-role sub-section-gate-read convention
  (still an open assumption per issue-1's own artifacts; a phase-2
  implementer question, not this proposal's).
</content>
