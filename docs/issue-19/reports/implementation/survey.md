# Survey — issue #19 (test-env resolution adoption)

## Convention being adopted
`docs/specs/test-env-resolution.md` in the `on-the-record` repo (issue
#551) defines: resolution order (`CLAUDE_PLUGIN_ROOT_CORE` with a
non-empty `hooks/lib/gate-lib.sh` -> caller-supplied sibling candidates
-> SKIP), and a SKIP contract (stderr message
`SKIP: core plugin unreachable — unverifiable outside spawn env`, exit
`75`/`EX_TEMPFAIL`, distinct from a gate's own 0/1/2). Reference impl is
a Python module (`gates/test_env_resolve.py`) with a bash-CLI adoption
shape (`python3 -m gates.test_env_resolve <candidates...>`) and a
pytest-fixture adoption shape. This rulebook has neither a `gates/`
Python package nor pytest — it is pure bash.

## Current write set and how each fails outside spawn env
- `strategic-fit-gate/hooks/strategic-fit-gate.sh`,
  `multi-axis-scoring/hooks/multi-axis-scoring-gate.sh`,
  `batna-zopa/hooks/batna-zopa-gate.sh`,
  `evidence-discipline/hooks/evidence-discipline-gate.sh`,
  `term-sheet-structure/hooks/term-sheet-structure-gate.sh` — each
  sources `${CLAUDE_PLUGIN_ROOT_CORE:-.../../core}/hooks/lib/gate-lib.sh`
  and `exit 2` (its own "deny" code) if that fails. No sibling `../../core`
  exists in a plain checkout of this repo, so outside spawn env every
  test that expects `allow` instead reads as `deny` — a real assertion
  failure, indistinguishable from the gates having actually regressed.
- `tests/strategic-fit-gate-tests.sh`, `tests/multi-axis-scoring-tests.sh`,
  `tests/batna-zopa-tests.sh`, `tests/evidence-discipline-tests.sh`,
  `tests/term-sheet-structure-tests.sh` — each invokes its gate as a
  subprocess with `report()` assertions; none currently resolves/skips
  on missing core. **Reproduced**: `env -u CLAUDE_PLUGIN_ROOT_CORE bash
  tests/run-gate-tests.sh` -> exit 1, ~28 misleading FAILs across the
  5 suites, all of shape `want=allow got=deny`. With `CLAUDE_PLUGIN_ROOT_CORE`
  set (spawn env, as in this session) the same run is `0 failed` across
  all suites.
- `tests/run-gate-tests.sh` — aggregates the 5 suites' exit codes into
  one pass/fail; has no notion of "skipped" today.
- `tests/deny-only-check.sh` — its static grep half has no core
  dependency, but `substance_probe()` invokes all 6 plugins' `*-gate.sh`
  scripts directly (same core-sourcing failure mode) and currently
  reports `FAIL` (not SKIP) when none can refuse, which outside spawn
  env is environment noise, not a real regression finding.
- `tests/parse-check.sh` — pure `bash -n` syntax check, no core
  dependency at all. This is this repo's instance of the convention's
  documented "known exception" (`gates/test_skip_gate.py` in
  on-the-record) — out of scope for adoption, same as that doc states.

## Design gap the convention leaves open for this repo
The convention's own "Bash test runner" adoption shape assumes a
`gates.test_env_resolve` Python module is importable/CLI-invokable in
the consuming repo. This repo has no Python tooling and no `gates/`
package — vendoring the on-the-record Python module in would add a new
runtime dependency (Python) to a pure-bash test suite for a ~15-line
resolution/SKIP contract, and copying source across repos (rather than
depending on a package) is exactly the kind of ad hoc duplication the
convention exists to end. The proposal below reimplements the same
resolution order and SKIP contract as bash, sourced once from
`tests/lib/resolve-core.sh` by all six consumers — see the proposal's
Rationale for the alternative considered and rejected.

## No skip condition applies
This is not a pure bugfix (it changes control flow: FAIL -> SKIP with a
distinct exit code, across 7 files) and the convention leaves an
implementation-shape decision open for non-Python consumers (previous
section) — so scouting/proposal-with-rationale applies normally, not a
skip.
