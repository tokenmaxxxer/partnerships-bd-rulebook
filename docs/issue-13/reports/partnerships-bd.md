# Phase-2 record — issue-13

Subject: issue-13. Executed the gate A+ final-closure remediation per
`docs/issue-13/proposals/gate-a-plus-remediation.md`, approved via
`APPROVE issue-13/partnerships-bd`.

## What was done

Fixed all four residual defects the 2026-08-01 re-audit found against the
issue-10 landing: the dead Bash-matcher branch, the fail-open verdict
`case` fall-through, and the README's `NotebookEdit` overstatement; added
the missing `missing-core` test case (paired with the source-guard
prerequisite fix, itself blocking) to every gate's own test file; and
confirmed `hooks.json`/README/manifest carry no stale role names or ghost
files.

## Why

Same "our own gates must clear the bar we hold counterparties to" fit as
issue-10 (`docs/issue-13/proposals/gate-a-plus-remediation.md`, "Strategic
fit and compounding value"). A role whose job is judging deal structure
cannot ship review tooling with a matcher/code mismatch and a fail-open
verdict path.

## Upstream basis

- Core issue #75 (`gate-lib.sh` source-guard mandate,
  `gate_bash_write_targets` Python parity, `compliance-check.sh`'s
  unguarded-source detection) — landed, PR #77.
- This repo's phase-1 survey and proposal
  (`docs/issue-13/reports/partnerships-bd/current-state-survey.md`,
  `docs/issue-13/proposals/gate-a-plus-remediation.md`).
- Approval: issue comment `APPROVE issue-13/partnerships-bd` by
  `JiwonJung94` (approvers.md account).

## BATNA

BATNA (walk-away alternative, internal tooling — no counterparty): if this
record is not written, the 5 gates keep running with the code changes
already landed but no compliance-check/full-suite record on file —
strictly worse for future auditors than landing this record, not worse
than pre-remediation baseline. No counterpart is party to this internal
gate-remediation work, so no ZOPA estimate applies (consistent with the
phase-1 proposal's own BATNA/ZOPA section).

## Six-axis scoring (multi-axis-scoring, applied to this record's own execution)

- strategic/ICP fit: weight 3, score 5 — closes this role's own
  credibility gap in its review tooling.
- financial health: weight 1, score 5 — zero external cost, internal-repo
  change only.
- legal/compliance posture: weight 2, score 5 — closes the fail-open
  verdict-fall-through and unguarded-source gaps; compliance-check now
  passes clean.
- operational capability: weight 2, score 5 — executed across 5
  `hooks.json` files, 5 gate scripts, 1 README paragraph, and 5 test
  files in one branch; full suite green.
- cultural fit: weight 1, score 5 — every fix reused an already-landed
  core primitive or this repo's own existing test-file convention.
- compounding-value: weight 3, score 5 — matches the phase-1 proposal's
  own compounding-value framing; zero new maintenance surface introduced.

## loop_state

loop_state: landed

## Open findings

None.

## Actions taken

1. **Matcher-code alignment** (proposal section 1): `hooks.json`'s
   `matcher` field changed from `"Write|Edit|MultiEdit"` to
   `"Write|Edit|MultiEdit|Bash"` in all 5 methodology plugins
   (`strategic-fit-gate`, `multi-axis-scoring`, `batna-zopa`,
   `evidence-discipline`, `term-sheet-structure`). No gate-script change —
   each script's live `if [ "$tool_name" = "Bash" ]; then ... fi` block
   (already present from issue-10) is now reachable. `NotebookEdit`
   deliberately not added — no gate has matching logic for it (would
   recreate the same matcher/code mismatch this fixes).

2. **Verdict fall-through fix** (proposal section 2): every gate's
   `case "$verdict" in ... esac` gained an explicit `*) gate_deny "$GATE_NAME"
   "unrecognized verdict from substance check: $verdict" ;;` arm as the
   last arm, and (where missing) an explicit `PASS) gate_allow ;;` arm.
   The trailing unconditional `gate_allow` after each `esac` was removed —
   every path through the `case` now exits explicitly, either via
   `gate_deny` or the `PASS` arm's `gate_allow`, so an unrecognized verdict
   string denies instead of silently falling through to the trailing
   allow.

3. **README `NotebookEdit` correction** (proposal section 3): the
   "Write/Edit/MultiEdit/NotebookEdit reconstruction" claim
   (`README.md:54-60`) is replaced with "Write/Edit/MultiEdit
   reconstruction (plus Bash-tool write-target detection via
   `gate_bash_write_targets`, matched in each plugin's `hooks.json`)" —
   removing the `NotebookEdit` claim entirely rather than reweakening it,
   since no gate script in this repo has `NotebookEdit`-specific handling
   and core's own `gate_reconstruct_write` for `NotebookEdit` returns only
   a single cell's `new_source`, not a full-document blob.

4. **Source-guard fix** (proposal section 5, prerequisite for section 4):
   all 5 gate scripts' `. "${CLAUDE_PLUGIN_ROOT_CORE:-...}/hooks/lib/
   gate-lib.sh"` source line gained the `|| { echo "<gate-name>.sh: cannot
   source gate-lib.sh" >&2; exit 2; }` guard core-canon's own doc comment
   mandates (issue-75-confirmed defect: an unguarded source that fails
   when core is unreachable runs no code — including no `gate_*` function
   definition — after which the kill-switch check reads the resulting
   "command not found" as the switch being off, silently allowing
   everything).

5. **Missing-core test case** (proposal section 4): each of the 5
   `tests/<plugin>-tests.sh` files gained a `missing-core-source-guard-deny`
   case — a `mktemp -d` fixture with no `core/` checkout, invoking the gate
   with `CLAUDE_PLUGIN_ROOT_CORE` pointed at a nonexistent path inside it,
   asserting exit code 2 (deny). This exercises the section-4 fix: against
   the pre-remediation unguarded source, this case would have failed
   (allow instead of deny).

6. **Manifest/README name audit** (proposal cross-reference, issue
   requirement 4): grep-swept `hooks.json`, `.claude-plugin/plugin.json`
   (all 6), `.claude-plugin/marketplace.json`, and `README.md` for stale
   role names or ghost-file references. Found none — issue-10 already
   closed this; `partnerships-bd/hooks/record-fields.config` (not a ghost
   file) is correctly listed in README's Layout section, and marketplace
   plugin `source` paths match the actual 6 top-level plugin directories.

## Compliance verification

Ran `core/hooks/tests/compliance-check.sh` (issue-72/issue-75 canon)
against each of the 5 gate directories' `hooks/`, `CLAUDE_PLUGIN_ROOT_CORE`
pointed at a fresh `tokenmaxxxer-core` checkout (commit `52bdc15`, issue-75
landed):

```
=== strategic-fit-gate ===
compliance-check: ok — .../strategic-fit-gate/hooks/strategic-fit-gate.sh
=== multi-axis-scoring ===
compliance-check: ok — .../multi-axis-scoring/hooks/multi-axis-scoring-gate.sh
=== batna-zopa ===
compliance-check: ok — .../batna-zopa/hooks/batna-zopa-gate.sh
=== evidence-discipline ===
compliance-check: ok — .../evidence-discipline/hooks/evidence-discipline-gate.sh
=== term-sheet-structure ===
compliance-check: ok — .../term-sheet-structure/hooks/term-sheet-structure-gate.sh
```

All 5 clean (`rc=0` each) — the new `||`-guarded source line is exactly
what `compliance-check.sh`'s unguarded-source check (issue-75) looks for.

Also ran, same `CLAUDE_PLUGIN_ROOT_CORE`:

```
/bin/bash tests/parse-check.sh      # 20 files, all ok
/bin/bash tests/run-gate-tests.sh   # 98 cases, 0 failed
                                     # (20+19+20+19+20, incl. the 5 new
                                     #  missing-core cases)
/bin/bash tests/deny-only-check.sh  # ok, no permissionDecision:allow anywhere
```

Full suite green, including the `missing-core` cases the source-guard fix
makes assertable.

## Next steps

None required for this issue. Future methodology-gate additions to this
repo should keep `hooks.json`'s matcher and each gate script's tool-name
branches in lockstep, and add a `missing-core` case alongside any new
gate's test file from the start rather than retrofitting it.
