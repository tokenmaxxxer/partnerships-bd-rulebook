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
