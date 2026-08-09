---
status: proposed
files:
  - tests/lib/resolve-core.sh
  - tests/strategic-fit-gate-tests.sh
  - tests/multi-axis-scoring-tests.sh
  - tests/batna-zopa-tests.sh
  - tests/evidence-discipline-tests.sh
  - tests/term-sheet-structure-tests.sh
  - tests/deny-only-check.sh
  - tests/run-gate-tests.sh
  - docs/issue-19/decisions/2026-08-09-bash-native-resolver.md
---

## Request
Adopt the canonical test-env resolution convention landed at
on-the-record `docs/specs/test-env-resolution.md` (issue #551) across
this rulebook's gate-test scripts: resolve core's `gate-lib.sh` via
`CLAUDE_PLUGIN_ROOT_CORE` -> sibling candidates -> SKIP (distinct exit
code, explicit stderr message), so a plain checkout without spawn env
gets an honest SKIP instead of misleading FAILs. Do not weaken any
assertion that runs when core is reachable.

## Constraints
- Resolution order and SKIP contract must match the convention exactly:
  env var (non-empty `gate-lib.sh`) -> caller-supplied sibling
  candidates -> SKIP with `SKIP: core plugin unreachable — unverifiable
  outside spawn env` on stderr and exit `75`.
- No network fetch fallback (convention explicitly excludes it from the
  canonical SKIP contract).
- Every adopting script must reference the convention doc (issue
  acceptance check: `grep` for `test-env-resolution`).
- Assertions that currently pass with core reachable must keep passing
  unchanged — this is a control-flow wrapper, not a rewrite of gate
  behavior.
- `tests/parse-check.sh` has no core dependency (pure `bash -n`) and is
  the convention's documented exception — out of scope.

## Rationale
Considered vendoring on-the-record's Python reference module
(`gates/test_env_resolve.py`) into this repo and invoking it via
`python3 -m gates.test_env_resolve <candidates>` per the convention's
own "Bash test runner" adoption shape. Rejected: this repo has no
Python tooling anywhere in its test suite today, so adopting it would
add a new runtime dependency (Python 3 on the test-running machine) for
a ~15-line resolve/SKIP contract, and the only way to get the module
into this repo without a shared package registry is copying its source
— exactly the ad hoc, hand-rolled-per-consumer duplication the
convention exists to end (per the convention doc's own "Problem"
section). Instead: reimplement the same resolution order and SKIP
contract natively in bash, in one shared file
(`tests/lib/resolve-core.sh`) sourced by every consumer, so there is
still exactly one place the order/contract logic lives in this repo,
consistent with the convention's intent even though the mechanism
differs from its literal reference implementation. This shape decision
is recorded as an ADR since it's a library-choice divergence from the
convention's stated reference (per the doctrine ladder for
implementation).

## What will be done
- Add `tests/lib/resolve-core.sh`: a sourceable bash function
  `resolve_core` implementing the convention's order — checks
  `$CLAUDE_PLUGIN_ROOT_CORE` for a non-empty `hooks/lib/gate-lib.sh`,
  then iterates caller-supplied candidate paths, else prints the SKIP
  message to stderr and returns 75; on success prints the resolved path
  to stdout and returns 0. File header comments cite
  `docs/specs/test-env-resolution.md`.
- In each of the 5 gate-test scripts (`strategic-fit-gate-tests.sh`,
  `multi-axis-scoring-tests.sh`, `batna-zopa-tests.sh`,
  `evidence-discipline-tests.sh`, `term-sheet-structure-tests.sh`):
  source `tests/lib/resolve-core.sh`, resolve core near the top
  (candidates: `../core`, `../../tokenmaxxxer-core/core`) before running
  any `run()`/assertion, and on SKIP print the message and `exit 75`
  instead of running assertions. On successful resolution, export the
  resolved path as `CLAUDE_PLUGIN_ROOT_CORE` for the subprocess calls so
  behavior is unchanged when core is reachable.
- In `tests/deny-only-check.sh`: resolve core before `substance_probe()`
  runs; if unresolved, print the SKIP message, skip `substance_probe()`
  only (the static grep half has no core dependency and keeps running
  unconditionally), and let the script's exit reflect skip via `75` if
  the static half also found nothing to fail on, else keep the static
  half's own exit code.
- In `tests/run-gate-tests.sh`: treat a suite's exit `75` as skipped,
  not failed — track skipped-vs-failed separately, print a `-- N
  skipped --` summary line, and keep `overall_fail=1` only for actual
  suite failures (skips do not fail the run).
- Add `docs/issue-19/decisions/2026-08-09-bash-native-resolver.md`
  recording the bash-native-vs-vendored-Python choice from Rationale.

## Out of scope
- Changing gate behavior/assertions themselves.
- Adopting the convention in `tests/parse-check.sh` (documented
  exception, no core dependency).
- Any change to the on-the-record convention doc or its Python
  reference module.
- A network-fetch fallback for core resolution.

## How you'll know it worked
- `env -u CLAUDE_PLUGIN_ROOT_CORE bash tests/run-gate-tests.sh` (run
  from a plain checkout with no sibling `core`) exits with the SKIP
  contract surfaced per suite (no misleading FAIL) and a distinct
  overall signal — not exit `0`-as-if-passed and not exit `1`-as-if-a-
  real-regression.
- With `CLAUDE_PLUGIN_ROOT_CORE` set to a real core checkout (spawn env,
  as verified in this session before the change: `0 failed` across all
  5 suites), the same run still shows `0 failed` across all suites,
  unchanged.
- `grep -rl test-env-resolution tests/` matches all 7 adopted files.
- `bash tests/parse-check.sh` still passes (bash 3.2 parseable) on every
  touched file.
