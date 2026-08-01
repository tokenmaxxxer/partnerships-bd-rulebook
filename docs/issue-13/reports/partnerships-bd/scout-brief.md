# issue-13 scout brief (brief, per scout-directive protocol)

Scope: this is a tooling/guard-design task with real design latitude in
*how* to fix each defect (e.g. where to add the default-deny arm, whether
the missing-core test lives per-gate or as one shared harness), so a scout
pass is warranted before the remediation proposal is written.

**Scouting was skipped for external sources: no web-search tool
(`WebSearch`/`WebFetch`) is available to this session** — only local
filesystem/Bash/Read tools were reachable. No external exemplar (ESLint
rule+fixture conventions, golden-file test suites, etc.) was fetched or
cited; nothing below is a fabricated citation.

In place of external scouting, the design draws on the two internal
precedents already reachable in this session, which are load-bearing and
directly on-point:

1. **Core's own `missing-core` regression test**
   (`core/hooks/tests/run-gate-lib-tests.sh:230-246`, `mark missing-core`)
   is the existing convention for exactly this test shape in this
   codebase: point `CLAUDE_PLUGIN_ROOT_CORE` at a nonexistent directory
   inside a throwaway tempdir (`$td/no-such-core`) and assert the gate
   denies. The proposal reuses this shape rather than inventing a new one.
2. **Issue-10's own mandatory-test-case list**
   (`docs/issue-10/proposals/gate-a-plus-remediation.md:137-157`) already
   established the per-gate fixture-test convention this repo uses (one
   `tests/<plugin>-tests.sh` per gate, each case a synthetic JSON payload
   piped into the gate script as a subprocess, asserted against exit code
   + stderr content). The proposal's missing-core and default-deny-arm
   test cases are additions to that same file shape, not a new harness.

Net effect: the remediation design (next document) is grounded entirely in
this repo's and core's own already-established test/gate conventions, with
no external framework comparison. If a wider survey of comparable
lint-rule/fixture or golden-file conventions is wanted before phase-2
executes, that should be flagged explicitly as a follow-up requiring
web-search tool access, not assumed to have happened here.
