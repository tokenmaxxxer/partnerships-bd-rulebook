---
code_under_review:
  - tests/lib/resolve-core.sh
  - tests/strategic-fit-gate-tests.sh
  - tests/multi-axis-scoring-tests.sh
  - tests/batna-zopa-tests.sh
  - tests/evidence-discipline-tests.sh
  - tests/term-sheet-structure-tests.sh
  - tests/deny-only-check.sh
  - tests/run-gate-tests.sh
  - docs/issue-19/decisions/2026-08-09-bash-native-resolver.md
type: feature
breaking: false
verdict: pass
loop_state: landed
---

# Implementation record — issue #19

## What was done
Adopted the canonical test-env resolution convention
(`docs/specs/test-env-resolution.md`, on-the-record issue #551) across
this rulebook's gate-test scripts, per the approved phase-1 proposal
(`docs/issue-19/proposals/2026-08-09-test-env-resolution-adoption.md`):

- Added `tests/lib/resolve-core.sh`: a sourceable `resolve_core`
  function implementing the convention's resolution order
  (`CLAUDE_PLUGIN_ROOT_CORE` -> caller-supplied sibling candidates ->
  SKIP) and SKIP contract (stderr message, exit 75).
- Sourced it from all 5 gate-test scripts
  (`strategic-fit-gate-tests.sh`, `multi-axis-scoring-tests.sh`,
  `batna-zopa-tests.sh`, `evidence-discipline-tests.sh`,
  `term-sheet-structure-tests.sh`): each resolves core near the top and
  exits 75 with the SKIP message before running any assertion when core
  is unreachable; on success, exports the resolved path as
  `CLAUDE_PLUGIN_ROOT_CORE` so subprocess gate invocations are
  unaffected.
- `tests/deny-only-check.sh`: the static `permissionDecision` grep half
  runs unconditionally (no core dependency); `substance_probe()` (which
  invokes all 6 plugins' gate scripts) now resolves core first and
  SKIPs with the convention message when unreachable, instead of
  reporting a misleading FAIL.
- `tests/run-gate-tests.sh`: tracks suite exit 75 as skipped (not
  failed) separately from real failures, prints a `-- N skipped --`
  summary line, and keeps `overall_fail=1` reserved for actual suite
  failures.
- `docs/issue-19/decisions/2026-08-09-bash-native-resolver.md`: ADR
  recording the bash-native-vs-vendored-Python library choice.

## Why
The issue requires gate-test scripts to SKIP honestly (not FAIL
misleadingly) outside the CI/spawn environment where core is reachable,
per the canonical convention. Bash-native reimplementation (rather than
vendoring the convention's Python reference module) avoids adding a new
runtime dependency to a pure-bash test suite — see the ADR for the full
rationale (alternative considered and rejected).

## Upstream basis
Basis: `docs/issue-19/proposals/2026-08-09-test-env-resolution-adoption.md`
(approved via issue comment `APPROVE issue-19/implementation` by
`JiwonJung94`, an approvers.md account, 2026-08-09). Survey:
`docs/issue-19/reports/implementation/survey.md`.

## What did not work
None.

## Verification performed
- `env -u CLAUDE_PLUGIN_ROOT_CORE bash tests/run-gate-tests.sh` (no
  sibling core, spawn env unset): all 5 suites print the exact SKIP
  message and exit 75; `run-gate-tests.sh` reports `-- 5 skipped --`
  and exits 0 (not the misleading pre-change `~28 FAIL` / exit 1).
- `env -u CLAUDE_PLUGIN_ROOT_CORE bash tests/deny-only-check.sh`: static
  half still runs and passes; `substance_probe` SKIPs with the
  convention message; script exits 0.
- `bash tests/run-gate-tests.sh` (spawn env, `CLAUDE_PLUGIN_ROOT_CORE`
  set as in this session): all 5 suites unchanged — 98 assertions
  total, `0 failed` in every suite, matching the proposal's stated
  pre-change baseline.
- `grep -rl test-env-resolution tests/` matches all 7 adopted files
  (5 gate-test scripts, `run-gate-tests.sh`, `deny-only-check.sh`) plus
  `tests/lib/resolve-core.sh` itself.
- `bash tests/parse-check.sh`: 20/20 files ok, including the new
  `tests/lib/resolve-core.sh`.

## Doc-placement ladder
- [x] Library-choice decision (bash-native vs. vendored Python) ->
  `docs/issue-19/decisions/2026-08-09-bash-native-resolver.md`.
- No env var, config key, new dependency, migration, or setup step was
  introduced — no handbook update required.

## Open findings
None — after-proposal warrant hunt (phase 1) recorded no finding.

## Warrant hunt
Diff at landing: 9 files changed (`tests/lib/resolve-core.sh` new,
5 gate-test scripts, `tests/deny-only-check.sh`,
`tests/run-gate-tests.sh`, plus this record and the ADR) — over the
docs-only fast-path threshold. Given the headless single-shot
constraint (no later turn to consume an async hunter result, per
contract v3 s22), a background dispatch was not made; instead this
session performed its own targeted probe of the stance due at this
transition:
- Checked that `resolve_core`'s SKIP exit code (75) cannot collide with
  a real gate's own exit codes (0 allow / 2 deny) anywhere it is
  propagated: `run-gate-tests.sh` explicitly special-cases only `75`;
  any other nonzero is treated as a real failure. No collision found.
- Checked that the `missing-core-source-guard-deny` assertion in each
  gate-test script (which explicitly sets
  `CLAUDE_PLUGIN_ROOT_CORE="$td/no-such-core"` per-call) is not
  shadowed by the new top-level `export CLAUDE_PLUGIN_ROOT_CORE`: a
  per-call `env VAR=x` overrides an exported shell variable for that
  subprocess only, confirmed by the passing run above (`ok
  missing-core-source-guard-deny deny` in all 5 suites with core
  reachable). No collision found.

No finding.

## Anomalies
`.warrant-hunt.count` was found deleted (untracked-as-deletion) in the
working tree at session start, before any work in this session touched
it. Not investigated further — outside this issue's frozen write set.
