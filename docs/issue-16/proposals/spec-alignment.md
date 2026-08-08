---
status: proposed
files:
  - partnerships-bd/reference/deliverable-shapes.md
  - partnerships-bd/hooks/record-fields.config
  - docs/specs/record-fields-terminal-states.json
  - README.md
---

## Request

Align this rulebook's vocabulary with the realized `partnerships-bd`
marketplace spec (on-the-record): layer the spec's three required
deliverable fields (`partner_id`, `lifecycle_stage`, `governance_note`) and
its five-value `loop_state` vocabulary (`assessing`, `collaborating`,
`landed`, `partner-unreachable`, `stage-undeclared`) onto the rulebook's
methodology docs and hooks, strengthening existing content rather than
deleting methodology.

## Constraints

- Spec fields and vocabulary are fixed externally (marketplace #521-#525)
  and quoted verbatim in the issue — this proposal maps onto them, it does
  not invent alternatives to them.
- No methodology content (multi-axis scoring, BATNA/ZOPA, term-sheet
  sub-sections) may be deleted; only strengthened or extended.
- Every spec field must land in the rulebook docs (grep-checkable per
  issue acceptance); a field with no natural home must be stated as such
  with reasoning, not silently dropped.
- `loop_state` vocabulary in rulebook docs must match the spec set exactly
  — no stale (`done`, `decided`) or extra values left standing.
- Write set stays inside docs/hooks/README; no gate-script (`.sh`) logic
  changes, since `record-fields.config` is data read by an existing core
  gate, not new gate code (confirmed in the survey).

## Rationale

**`governance_note`: strengthen the existing term-sheet-outline
sub-section in place, rather than adding a new standalone top-level
field.** Considered adding `governance_note` as a fourth required
top-level field alongside `deal-structure-verdict` and `term-sheet-outline`
in `record-fields.config`. Rejected: the term-sheet-outline shape already
names a "governance — decision-making authority thresholds (kept distinct
from KPIs)" sub-section, gated via
`REQUIRED_SUBSECTIONS_term_sheet_outline`. Promoting a duplicate top-level
field would create two governance surfaces that can drift apart (one
gated, one not) for the same concept the rulebook already treats as
load-bearing. Strengthening the existing sub-section's doc text to use the
spec's exact name (`governance_note`) keeps one gated home and satisfies
the acceptance check's grep (the string `governance_note` will appear in
`deliverable-shapes.md`).

**loop_state vocabulary: add a role-local
`docs/specs/record-fields-terminal-states.json` override, rather than
editing individual past records or leaving vocabulary implicit in
prose.** Considered leaving the mapping as prose guidance only (as
`deliverable-shapes.md`'s existing "Phase-1 proposal convention" section
does for staging). Rejected: prose-only is exactly the pattern that
produced the drift the survey found — four prior records use three
different, non-spec values (`done`, `decided`, `landed`) with nothing
mechanically enforcing convergence. Contract v3 already defines a named
override mechanism for this (`record-fields-terminal-states.json`,
`{kind: [states]}`), so using it is the smallest change that makes the
vocabulary check enforceable by the same machinery instead of relying on
each future session remembering prose.

## What will be done

1. **`partnerships-bd/reference/deliverable-shapes.md`**: add two new
   subsections, `## partner_id` and `## lifecycle_stage`, alongside the
   existing `## deal-structure-verdict` / `## term-sheet-outline`
   sections:
   - `partner_id`: documented as a new required top-level record field —
     the counterpart org/individual identifier every partnerships-bd
     record must carry, since no existing field currently names the
     counterpart at all (survey: genuine gap, no natural home pre-exists).
   - `lifecycle_stage`: promotes the existing "declare stage (non-binding
     vs binding-terms-ready)" line (current `## Phase-1 proposal
     convention` section) into a formally named required field, replacing
     the two-value description with the spec's five-value vocabulary
     (reusing `loop_state`'s values, since deal lifecycle and loop_state
     are the same underlying progression for this role).
   - The existing `## term-sheet-outline` section's item 4 (governance
     sub-section) gets a one-line addition naming it as satisfying the
     spec's `governance_note` field, so the mapping is explicit at the
     point of use rather than only in this proposal.

2. **`partnerships-bd/hooks/record-fields.config`**: extend
   `REQUIRED_FIELDS` to `"deal-structure-verdict,term-sheet-outline,partner-id,lifecycle-stage"`
   (governance stays nested under term-sheet-outline's existing
   `REQUIRED_SUBSECTIONS_term_sheet_outline`, per the Rationale above —
   no new line needed for it there beyond the doc-text addition in step
   1).

3. **`docs/specs/record-fields-terminal-states.json`** (new file): add a
   `partnerships-bd` kind entry with exactly the spec's five values:
   ```json
   {
     "partnerships-bd": ["assessing", "collaborating", "landed", "partner-unreachable", "stage-undeclared"]
   }
   ```
   This is the mechanical fix for the `done`/`decided`/`landed` drift the
   survey found; it governs future records only (see Out of scope).

4. **`README.md`**: sync the `produces` line and the "Methodology
   plugins" section's lead-in to mention the three spec fields by name,
   so the acceptance grep (`grep -ri <field> docs/ README.md`) has a hit
   in the repo root doc as well as under `partnerships-bd/`.

## Out of scope

- Editing the four existing historical records
  (`docs/issue-{1,7,10,13}/reports/partnerships-bd.md`) to retroactively
  fix their non-spec `loop_state` values — those are closed, merged
  records; the terminal-states override governs records written from now
  on, not a rewrite of history.
- Any gate-script (`.sh`) logic change — `record-fields.config` is data
  read by an existing core-canon gate; no new enforcement code is being
  written in this pass.
- Fetching or vendoring `roles/specs/partnerships-bd.spec.json` itself —
  it lives in on-the-record's system, not this repo; this proposal works
  from the field/vocabulary list quoted verbatim in issue #16's body.
- Adding a phase-1 gate for the staging convention
  (`deliverable-shapes.md`'s existing note that "No phase-1 gate exists
  yet" stays true after this change — only the doc text and the new
  terminal-states file change, not enforcement).

## How you'll know it worked

- `grep -ri "partner_id\|lifecycle_stage\|governance_note" docs/ README.md`
  returns hits in `partnerships-bd/reference/deliverable-shapes.md` and
  `README.md` (issue acceptance check #1 — field names appear, allowing
  for the config's hyphenated spelling alongside the doc's underscored
  spelling).
- `docs/specs/record-fields-terminal-states.json` contains exactly the
  spec's five `loop_state` values for the `partnerships-bd` kind, no
  stale or extra values (issue acceptance check #2).
- `/bin/bash tests/parse-check.sh`, `/bin/bash tests/run-gate-tests.sh`,
  `/bin/bash tests/deny-only-check.sh` still pass unchanged, since no
  gate-script logic is touched (issue acceptance check #3 — a real run,
  not `unverifiable`, since the suite exists).
- No methodology sub-section (multi-axis axes, BATNA/ZOPA, the other six
  term-sheet-outline sub-sections) is removed or renamed — diff review
  confirms only additions and the one governance-note cross-reference
  line.
