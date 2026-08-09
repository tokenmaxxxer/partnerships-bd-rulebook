# Handbook — tests/

Repo-root operational surface for running the gate-test suite locally.

## Run the checks

```
bash tests/parse-check.sh
bash tests/run-gate-tests.sh
bash tests/deny-only-check.sh
```

`parse-check.sh` and `deny-only-check.sh` are copied verbatim across
this rulebook family (per each file's own header comment) — do not
diverge them here; a fix belongs upstream and gets re-copied.

`run-gate-tests.sh` dispatches each of the 5 partnerships-bd
methodology plugins' own gate-test suite
(`tests/<plugin>-tests.sh`, one per plugin under
`strategic-fit-gate/`, `multi-axis-scoring/`, `batna-zopa/`,
`evidence-discipline/`, `term-sheet-structure/`) as its own subprocess,
and exits non-zero if any suite fails. Added issue-7 phase 2.

## Core resolution outside spawn env

Every gate-test suite (the 5 plugin suites plus `deny-only-check.sh`'s
`substance_probe`) resolves core via `tests/lib/resolve-core.sh`
(`resolve_core`), which follows the canonical order and SKIP contract
from `docs/specs/test-env-resolution.md` (on-the-record issue #551):
`CLAUDE_PLUGIN_ROOT_CORE` (if it has a non-empty `hooks/lib/gate-lib.sh`)
-> sibling `../core` / `../tokenmaxxxer-core/core` candidates -> SKIP
(stderr message, exit 75) with no assertions run. `run-gate-tests.sh`
treats a suite's exit 75 as skipped, not failed, and prints a `-- N
skipped --` summary line. On a plain checkout outside the spawn env
(no `CLAUDE_PLUGIN_ROOT_CORE`, no sibling core checkout), expect every
suite to SKIP rather than report misleading FAILs. Added issue-19
phase 2.
