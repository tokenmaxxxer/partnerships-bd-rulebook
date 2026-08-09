# Bash-native core resolver, not the vendored Python reference module

## Decision
Adopt `docs/specs/test-env-resolution.md`'s (on-the-record issue #551)
resolution order and SKIP contract via a bash-native reimplementation
(`tests/lib/resolve-core.sh`), not by vendoring the convention's Python
reference module (`gates/test_env_resolve.py`).

## Rationale
Considered invoking `python3 -m gates.test_env_resolve <candidates>` per
the convention's own "Bash test runner" adoption shape. Rejected: this
repo has no Python tooling anywhere in its test suite today, so adopting
it would add a new runtime dependency (Python 3 on the test-running
machine) for a ~15-line resolve/SKIP contract. There is no shared package
registry between this repo and on-the-record, so the only way to bring the
module in is copying its source — exactly the ad hoc, hand-rolled-per-
consumer duplication the convention exists to end (per the convention
doc's own "Problem" section).

Instead, the same resolution order and SKIP contract are reimplemented
natively in bash, in one shared file (`tests/lib/resolve-core.sh`) sourced
by every consumer, so there is still exactly one place the order/contract
logic lives in this repo — consistent with the convention's intent even
though the mechanism differs from its literal reference implementation.

## Consequences
- No new runtime dependency added to this repo's test suite.
- `tests/lib/resolve-core.sh` must be kept in sync by hand with the
  convention doc if the canonical order or SKIP contract ever changes,
  since it is not a shared package import.
