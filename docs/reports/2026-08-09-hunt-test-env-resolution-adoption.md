---
proposal: docs/issue-19/proposals/2026-08-09-test-env-resolution-adoption.md
---

# Hunt record — test-env-resolution-adoption

## after-proposal — stance 0: assume the gate just touched is bypassable — find the bypass.

Verdict: NO FINDING
Seed: docs/issue-19/proposals/2026-08-09-test-env-resolution-adoption.md, docs/issue-19/reports/implementation/survey.md (commit df12332, docs-only)
cap_seconds: 60
tier: default
diff_stat_lines: 175
started_at: 2026-08-09T09:41:07+09:00
ended_at: 2026-08-09T09:43:00+09:00

Checked whether tests/lib/resolve-core.sh or a skip-tracking run-gate-tests.sh
exists yet to probe for a bypass. Neither exists: `find . -iname
"resolve-core.sh"` returns nothing, and the current tests/run-gate-tests.sh
has no SKIP (exit 75) handling at all -- it treats any nonzero exit from a
suite (including a hypothetical future SKIP) as `overall_fail=1`, i.e. today
SKIP would surface as FAIL, not be swallowed as a pass. The proposal is
docs-only; the resolver contract and skip-tracking logic described are not
yet written in any script. Per the reproduction requirement, there is no
command to run against code that does not exist, so no bypass can be
demonstrated at this transition. Re-probe after the implementation commit
lands.
