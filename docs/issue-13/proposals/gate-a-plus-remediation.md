# issue-13 phase-1 proposal: gate A+ final closure remediation design

Status: PROPOSAL — phase 1 only (research + design). This document does
**not** implement anything and does **not** approve anything. Phase-2
(actual code changes) opens only after a human issues an Approve per
`docs/specs/approvers.md` and role-handoff contract v3 s19. No `APPROVE`
is issued in this document.

Full defect evidence with file:line citations:
`docs/issue-13/reports/partnerships-bd/current-state-survey.md`. Scouting
note: `docs/issue-13/reports/partnerships-bd/scout-brief.md` (no
web-search tool access this session; design grounded in this repo's and
core's own existing test conventions only).

## Stage

Non-binding: this is a design proposal for internal gate tooling, not a
deal term sheet — there is no counterparty and no binding-terms-ready
stage applicable to this subject matter.

## Strategic fit and compounding value

Strategic/ICP fit: this repo's own methodology gates are the
partnerships-bd role's core credibility surface — a role whose job is
judging whether a deal structurally holds cannot run its own review
tooling with a dead Bash-matcher branch, a fail-open verdict
fall-through, and a README claim (NotebookEdit reconstruction) that
doesn't match the live wiring. Closing these residual gaps is the same
"our own gates must clear the bar we hold counterparties to" fit issue-10
already established
(`docs/issue-10/proposals/gate-a-plus-remediation.md:16-22`).

Compounding value: every fix proposed below reuses an already-landed core
primitive (`gate_bash_write_targets`, the guarded-source convention, the
`missing-core` test shape) or an already-established in-repo test-file
convention, rather than introducing anything new — so the fix, once
applied, requires zero new maintenance surface beyond what issue-10
already created.

## BATNA and ZOPA

BATNA (walk-away alternative): if this proposal is not approved, the 5
gates keep running with the Bash-matcher gap, the verdict fall-through,
and the README overstatement live — worse than landing this fix, but not
worse than the gates' current (already fail-closed-on-crash) baseline;
nothing about walking away from this specific proposal breaks anything
that is not already broken today.

No external counterparty is party to this proposal (internal tooling
against this repo's own gates), so no ZOPA estimate applies — consistent
with issue-10's own proposal on the same non-applicability
(`docs/issue-10/proposals/gate-a-plus-remediation.md:41-42`).

This proposal is deliberately conservative: minimal-surface-area fixes for
the exact defects the survey located, reusing already-landed core-canon
primitives and this repo's own existing test-file shape, no new
abstractions or refactors beyond what each defect requires.

## 1. Matcher-code alignment fix

**Defect**: `hooks.json` matcher is `"Write|Edit|MultiEdit"` in all 5
methodology plugins (`{strategic-fit-gate,multi-axis-scoring,batna-zopa,
evidence-discipline,term-sheet-structure}/hooks/hooks.json:7`), but each
gate script's Python payload already branches on `tool_name == "Bash"`
(`*/hooks/*-gate.sh:38`) and each gate script's shell already has a live
`if [ "$tool_name" = "Bash" ]; then ... fi` block
(`*/hooks/*-gate.sh:84-96`, exact lines vary slightly per file — see
survey Defect 1). The code path is real and already has a direct-invocation
test (`tests/batna-zopa-tests.sh:167-171`); only the live wiring is
missing.

**Fix — minimal diff, one file per plugin, 5 files total**: change the
`matcher` string in each of the 5 `hooks.json` files from
`"Write|Edit|MultiEdit"` to `"Write|Edit|MultiEdit|Bash"`. No change to
any `.sh` file — the Bash-handling code already present is exactly what
issue-10 designed it to be
(`docs/issue-10/proposals/gate-a-plus-remediation.md:89-93`); it has simply
never been reachable. This is a one-line JSON change per file, the smallest
possible fix that closes the gap.

`NotebookEdit` is deliberately **not** added to the matcher in this
proposal — see section 3 (README fix) for why: no gate script currently
has `NotebookEdit`-specific handling, and adding the matcher entry without
matching code would create a new instance of the exact "matcher says one
thing, code says another" defect this section is fixing. If `NotebookEdit`
coverage is wanted, that is new gate-logic work belonging to a future
issue, not a 1-line matcher edit riding on this one.

## 2. Verdict fall-through fix (no default arm)

**Defect**: all 5 gates' `case "$verdict" in ... esac` blocks lack a
catch-all `*)` arm and are followed by an unconditional `gate_allow`
(survey Defect 2, e.g. `batna-zopa/hooks/batna-zopa-gate.sh:223-235`,
`strategic-fit-gate/hooks/strategic-fit-gate.sh:195-207`,
`multi-axis-scoring/hooks/multi-axis-scoring-gate.sh:186-198`). Any verdict
string the case doesn't recognize silently allows.

**Fix — minimal diff, one `case` block per gate, 5 files**: add an explicit
`*) gate_deny "$GATE_NAME" "unrecognized verdict from substance check: $verdict" ;;`
arm as the last arm in each `case "$verdict" in ... esac`, immediately
before the closing `esac`, in all 5 gate scripts. This makes "unrecognized
verdict" its own fail-closed branch instead of falling through to the
trailing `gate_allow`. The trailing `gate_allow` after each `esac` can then
be deleted (`multi-axis-scoring-gate.sh:198`, and equivalently in the other
4 files) since every path through the `case` now explicitly exits — either
via `gate_deny` (which itself calls `exit 2`) or an explicit `PASS)
gate_allow ;;` arm added where one is currently missing
(`strategic-fit-gate.sh` and `batna-zopa.sh` currently have no `PASS` arm
at all and rely entirely on the trailing `gate_allow`; both need a `PASS)
gate_allow ;;` arm added alongside the new `*)` deny arm so the intended
pass path stays intact and explicit).

This does not touch `gate_trap_fail_closed`, `gate_kill_switch_active`, or
any other core-canon call — it is scoped to the 5 gate-local `case`
blocks only, consistent with "gate-lib does not own doctrine semantics"
(issue-10 proposal's own scoping note, line 98-99).

## 3. README NotebookEdit correction

**Defect**: `README.md:54-60` claims "Write/Edit/MultiEdit/NotebookEdit
reconstruction" is what all 5 gates get from core canon. No `hooks.json`
in this repo matches `NotebookEdit` (confirmed by grep sweep, survey
Defect 4), and even core's own `gate_reconstruct_write` for `NotebookEdit`
(`gate-lib.py:146-151`) returns only a single cell's `new_source`, not a
full-document blob, per its own docstring
(`gate-lib.py:104-113`) — a materially different guarantee than the other
three tools.

**Fix — minimal diff, one paragraph, `README.md:54-60`**: change

```
fail-closed trap, kill-switch check, path normalization, and Write/Edit/
MultiEdit/NotebookEdit reconstruction — sourced via
```

to something that states only what is actually wired up in this repo —
e.g.

```
fail-closed trap, kill-switch check, path normalization, and Write/Edit/
MultiEdit reconstruction (plus Bash-tool write-target detection via
`gate_bash_write_targets`, matched in each plugin's `hooks.json`) —
sourced via
```

removing the `NotebookEdit` claim entirely rather than reweakening it,
since (per section 1) `NotebookEdit` support is not being added to the
matcher in this proposal. If a future issue adds real `NotebookEdit`
wiring, that is the point at which README should reference it again, with
its own citation to the matcher change and the cell-level (not
full-document) reconstruction shape core actually provides.

## 4. Missing-core test case design

**Defect**: no `missing-core` test case exists anywhere in this repo's
suite (survey: grep across all `tests/*.sh` for `missing.core` /
`CLAUDE_PLUGIN_ROOT_CORE` / `no-such-core` returns zero matches). This
matters doubly because the unguarded source line at `*/hooks/*-gate.sh:8`
in all 5 gates (survey, "Additional finding") means a missing-core test
written against the *current* code would likely **fail** — the unguarded
source falls through into undefined-function calls rather than exiting 2,
which the harness's own hook-exit contract (0/2 only fail-closed;
anything else is non-blocking) would read as an allow.

**Test design**: add one `missing-core` case to each of the 5
`tests/<plugin>-tests.sh` files, mirroring core's own convention at
`core/hooks/tests/run-gate-lib-tests.sh:230-246` (per scout brief):

- **Fixture**: a throwaway tempdir (`mktd`-equivalent, matching the
  pattern already used elsewhere in this repo's test files) containing no
  `core/` checkout at all.
- **Invocation**: run the gate script (e.g. `batna-zopa-gate.sh`) as a
  subprocess with `CLAUDE_PLUGIN_ROOT_CORE` set to a nonexistent path
  inside that tempdir (e.g. `"$td/no-such-core"`) and a syntactically
  valid tool-call payload piped to stdin (reuse an existing passing
  fixture payload from the same test file, since the point is to prove the
  *source failure* denies, independent of payload content).
  `CLAUDE_PROJECT_DIR` unset or pointed at the same tempdir, matching how
  other cases in the same file already invoke the script.
- **Assertion**: exit code 2 (deny), not 0. This is the assertion that
  currently would fail against the unguarded source line — making this
  test case and the section-5 source-guard fix below inseparable; the test
  should be added in the same phase-2 change as the guard fix, not as a
  standalone addition against still-unguarded scripts.

This reuses the exact fixture/assertion shape issue-10 already established
in these same 5 test files (survey: "Missing-core test-case audit" —
issue-10's own 6 mandatory cases already live in this shape); no new test
harness or helper file is proposed.

## 5. Source-guard fix (prerequisite for section 4, not separately named in the issue text but required to make it pass)

**Defect**: `*/hooks/*-gate.sh:8` in all 5 gates sources `gate-lib.sh`
without the `||` guard `core/hooks/lib/gate-lib.sh:11-18`'s own doc comment
mandates, and which `core/hooks/tests/compliance-check.sh:52-58` is built
to detect as a violation.

**Fix — minimal diff, one line per gate, 5 files**: change

```sh
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/gate-lib.sh"
```

to

```sh
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/gate-lib.sh" || { echo "<gate-name>: cannot source gate-lib.sh" >&2; exit 2; }
```

in all 5 gate scripts, matching core's own documented usage line verbatim
(`gate-lib.sh:18`). This is the change that makes the section-4
missing-core tests pass, and is also what
`core/hooks/tests/compliance-check.sh` checks for — running that script
against this repo's hooks directories (per issue's requirement #3,
"compliance-check 통과 record 기록") is the phase-2 exit criterion, not
something phase-1 runs.

## Six-axis scoring (applying multi-axis-scoring's own doctrine to this remediation)

- strategic/ICP fit: weight 3, score 5 — see "Strategic fit and
  compounding value" above.
- financial health: weight 1, score 5 — zero external cost, internal-repo
  change only, no vendor/spend.
- legal/compliance posture: weight 2, score 5 — directly closes the
  fail-open verdict-fall-through and unguarded-source gaps.
- operational capability: weight 2, score 4 — requires phase-2 execution
  across 5 `hooks.json` files, 5 gate scripts, 1 README paragraph, and 5
  test files; feasible in one branch, same shape as issue-10's own
  phase-2.
- cultural fit: weight 1, score 5 — every fix reuses an existing
  convention (core's `missing-core` test shape, this repo's own
  `*-tests.sh` fixture pattern); nothing new is introduced.
- compounding-value: weight 3, score 5 — see "Strategic fit and
  compounding value" above.

## Cross-reference: issue's own requirements checklist

| Issue requirement | Addressed by |
|---|---|
| 1. Fix all residual defects | Sections 1-3 (named defects) + 5 (prerequisite for 4) |
| 2. hooks.json matcher / code tool-coverage full alignment | Section 1 |
| 3. missing-core case in green full suite + compliance-check pass record | Sections 4-5 |
| 4. README/manifest: zero stale role names / ghost files | Survey found no *current* violation of this (issue-10 already fixed it); section 3 keeps README accurate going forward; no manifest change proposed since none is defective today |

## Explicitly out of scope for this proposal

- Any change to `core/hooks/lib/gate-lib.sh`/`gate-lib.py` themselves —
  reference only, per the repo's "never reimplemented locally" rule
  (`README.md:58`).
- Adding real `NotebookEdit` matcher/gate-logic support — flagged above as
  a separate future issue, not folded into this fix.
- Any change to `spawn.py`/on-the-record #182 — that landed at the harness
  level; nothing in this repo references or needs to change for it
  (survey, "Prerequisite state").
- Actual code edits to any `hooks.json`, `*-gate.sh`, `README.md`, or
  `tests/*.sh` file — this is phase-2 execution, opens only on a human
  Approve per `docs/specs/approvers.md`.
