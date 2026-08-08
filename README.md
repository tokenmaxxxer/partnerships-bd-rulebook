# partnerships-bd-rulebook

Rulebook for the `partnerships-bd` role (contract v3 role-handoff protocol), split off
per `docs/issue-160/proposals/role-taxonomy.md`'s round-3 promotion and
generated as skeleton scaffolding by issue-170.

- **decides**: 파트너십이 구조적으로 성립하는가
- **use_when**: 제휴/BD 딜 구조가 걸릴 때
- **produces**: deal structure verdict, term sheet outline, `partner_id`,
  `lifecycle_stage`, `governance_note` (marketplace spec fields, issue-16)
- **write_scope**: []
- **hand-off**: 법적 계약 검토는 → legal-compliance

## Install

```
claude plugin marketplace add tokenmaxxxer/partnerships-bd-rulebook
claude plugin install partnerships-bd
```

## Layout

- `partnerships-bd/.claude-plugin/plugin.json` — plugin manifest
- `partnerships-bd/hooks/hooks.json` — SessionStart + PreToolUse wiring
- `partnerships-bd/hooks/directive.sh` — SessionStart role directive
- `partnerships-bd/hooks/record-fields.config` — this role's required-field
  divergence, read by core canon's role-agnostic record-fields gate
- `partnerships-bd/agents/warrant-hunter.md` — rotating-stance hunt agent
- `docs/specs/approvers.md` — Approve-authority allowlist (see below)

The record-required-fields, commit-trailer, and handbook-sync gates are
core canon (issue-66), invoked by path against this role's `hooks/` tree —
never vendored here (`docs/handbooks/canon-scripts.md`).

This is scaffolding, not a finished rulebook: fill in doctrine detail,
handoff enforcement, and any role-specific progress gate before treating
it as load-bearing.

## Methodology plugins

Five methodology plugins live as siblings of the `partnerships-bd` role
plugin, one per adopted methodology. Each is self-contained (own
`directive.sh`, own gate script, own `tests/*-tests.sh`), fails closed, and
carries its own kill-switch env var. Records this role produces carry the
marketplace spec's three required fields — `partner_id`, `lifecycle_stage`,
`governance_note` — per `partnerships-bd/reference/deliverable-shapes.md`.

- `strategic-fit-gate` — checks the deal fits strategic intent before scoring starts
- `multi-axis-scoring` — scores the deal against the reference axes (`reference/axes.md`)
- `batna-zopa` — checks the BATNA/ZOPA negotiation position is stated
- `evidence-discipline` — checks the claims backing the deal case are evidenced
- `term-sheet-structure` — checks the term-sheet-outline field is structured

Phase-1 chain: `strategic-fit-gate` -> `multi-axis-scoring` -> `batna-zopa` -> `evidence-discipline`.
Phase-2: `multi-axis-scoring` + `batna-zopa` + `term-sheet-structure`.

Each gate references core canon `core/hooks/lib/gate-lib.sh` +
`gate-lib.py` (issue-72, `docs/handbooks/gate-house-standard.md`) for its
fail-closed trap, kill-switch check, path normalization, and Write/Edit/
MultiEdit reconstruction (plus Bash-tool write-target detection via
`gate_bash_write_targets`, matched in each plugin's `hooks.json`) —
sourced via `${CLAUDE_PLUGIN_ROOT_CORE:-...}/hooks/lib/gate-lib.sh`, never
reimplemented locally. `core/hooks/tests/compliance-check.sh` must pass
clean against each of the 5 gate directories.

### Kill switches

Each methodology gate reads its own env var; the on-spelling set is fixed
and case-insensitive (`1`/`true`/`yes`/`on`) — any other value, including a
typo or an unrecognized string, leaves the gate **active** (gate-lib's
`gate_kill_switch_active`, closing the fail-open bug where an unrecognized
value used to disable the gate):

- `STRATEGIC_FIT_GATE_OFF`
- `MULTI_AXIS_SCORING_GATE_OFF`
- `BATNA_ZOPA_GATE_OFF`
- `EVIDENCE_DISCIPLINE_GATE_OFF`
- `TERM_SHEET_STRUCTURE_GATE_OFF`

## Run the checks

```
/bin/bash tests/parse-check.sh
/bin/bash tests/run-gate-tests.sh
/bin/bash tests/deny-only-check.sh
```

The 5 methodology gates and `deny-only-check.sh`'s substance probe source
core canon at run time; outside an installed marketplace layout (where the
harness sets `CLAUDE_PLUGIN_ROOT_CORE` automatically), export it yourself
to point at a `core` plugin checkout, e.g.
`CLAUDE_PLUGIN_ROOT_CORE=/path/to/core /bin/bash tests/run-gate-tests.sh`.
