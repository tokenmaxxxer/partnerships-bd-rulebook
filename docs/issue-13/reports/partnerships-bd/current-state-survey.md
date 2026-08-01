# issue-13 current-state survey: gate A+ final closure

Phase: 1 (research only). No code changes made. Grounds `docs/issue-13/proposals/gate-a-plus-remediation.md`.

## Issue-13 scope (from `gh issue view 13`)

> 2026-08-01 재감사 잔여 결함 — 공통 외: Bash/NotebookEdit matcher 갭(죽은 분기), ZOPA 키워드
> 옵트인 잔존, verdict fall-through 잠재 fail-open, README NotebookEdit 과장
>
> 공통 선행 조건: core #75 (gate-lib source 가드 의무화 + compliance-check 검출 +
> missing-core 의무 테스트 + gate_bash_write_targets.py 이식), on-the-record #182
> (spawn.py의 CLAUDE_PLUGIN_ROOT_CORE 주입)
>
> 요구: (1) 잔여 결함 전부 수정, (2) hooks.json matcher와 코드의 도구 커버리지 완전 정합,
> (3) missing-core 케이스 포함 전 스위트 green + compliance-check 통과, (4) README/manifest
> 옛 역할명/유령 파일 잔재 0.

This is the second gate-A+ pass. Issue-10 (`docs/issue-10/reports/partnerships-bd.md`,
`docs/issue-10/proposals/gate-a-plus-remediation.md`) already landed (commit
`d8a392b`, PR #12): reference-adoption of core canon `gate-lib.sh`/`gate-lib.py`,
fail-closed trap, fixed-on-spelling kill switch, `gate_normalize_path`,
`gate_reconstruct_write`, and section/adjacency semantic checks across all 5
methodology gates in this repo (`strategic-fit-gate`, `multi-axis-scoring`,
`batna-zopa`, `evidence-discipline`, `term-sheet-structure`). Issue-13 audits
the *result* of that landing and the two named prerequisites.

## Prerequisite state (ground truth, read directly from the installed core checkout)

Core checkout resolved via `$CLAUDE_PLUGIN_ROOT_CORE` (this session's env):
`/home/jwjung/.claude/plugins/marketplaces/tokenmaxxxer/runs/rulebooks/tokenmaxxxer-core/core`.
No `core/` directory exists inside this repo — core is a sibling
plugin/checkout, consistent with README's "never vendored here" convention.

- **core #75 landed.** `core/hooks/lib/gate-lib.sh:93-95` defines
  `gate_bash_write_targets()` (sh) and `core/hooks/lib/gate-lib.py:159-171`
  defines the Python mirror `gate_bash_write_targets(command)` — both present,
  matching token-scan semantics (`[[:alnum:]_./~$-]+` / `[A-Za-z0-9_./~$-]+`).
  `core/hooks/lib/gate-lib.sh:11-18`'s doc comment mandates a **guarded**
  source line (`|| { echo ... ; exit 2; }`) precisely because an unguarded
  source that fails when core is unreachable leaves every `gate_*` call
  site reading a "command not found" (127) as if the kill switch were off —
  fail-open. `core/hooks/tests/run-gate-lib-tests.sh:230-246` (group 7,
  `mark missing-core`) is core's own regression test for this: source
  pointed at `$td/no-such-core` must deny, not allow.
  `core/hooks/tests/compliance-check.sh:52-58` detects an unguarded source
  line and reports it as a violation reason string ("sources gate-lib.sh
  with no || guard on the same line — fail-open when core is unreachable").
  `core/hooks/lib/gate-lib.py:88-153` (`gate_reconstruct_write`) documents
  `NotebookEdit` support: it returns the edited cell's `new_source` when
  `edit_mode` is `insert`/`replace` (lines 146-151), not a full-document
  text blob (a notebook is a sequence of cells, per the docstring at
  lines 104-113).
- **on-the-record #182**: no `spawn.py` file exists anywhere under this
  repo or in the reachable core checkout (`find` for `spawn.py` returned
  nothing); `CLAUDE_PLUGIN_ROOT_CORE` is set as an env var by the harness at
  session start (confirmed present in this session's environment) and is
  the variable every gate script in this repo already reads
  (`${CLAUDE_PLUGIN_ROOT_CORE:-...}` fallback pattern, see below) — the
  injection landed at the harness level; nothing in this repo needs to
  change for #182 itself. Not independently re-verifiable from inside this
  repo beyond "the env var this repo depends on is present and every gate
  script correctly falls back to a local `../../core` guess when absent."

## Defect 1 — hooks.json matcher / gate-script tool-coverage mismatch (dead branch)

Every one of the 5 methodology gates' `hooks.json` restricts `PreToolUse` to
`"matcher": "Write|Edit|MultiEdit"` — **not** `Bash`, **not** `NotebookEdit`:

- `batna-zopa/hooks/hooks.json:7`
- `strategic-fit-gate/hooks/hooks.json:7`
- `term-sheet-structure/hooks/hooks.json:7`
- `evidence-discipline/hooks/hooks.json:7`
- `multi-axis-scoring/hooks/hooks.json:7`

Yet every one of the 5 gate scripts contains a live `Bash`-tool-input branch
that the matcher can never route a real `Bash` tool call to:

- `batna-zopa/hooks/batna-zopa-gate.sh:38` (`tool_input.get("command", "") if tool_name == "Bash" else ""`)
  and `:84-96` (`if [ "$tool_name" = "Bash" ]; then ... gate_bash_write_targets ...`)
- same shape at `strategic-fit-gate/hooks/strategic-fit-gate.sh:38,84-91`,
  `term-sheet-structure/hooks/term-sheet-structure-gate.sh:38,84-90`,
  `evidence-discipline/hooks/evidence-discipline-gate.sh:38,84-90`,
  `multi-axis-scoring/hooks/multi-axis-scoring-gate.sh:38,84-90` (grep sweep,
  same line numbers across all 5 files — they were migrated from one
  template).

This is exactly the issue-10 proposal's own caveat
(`docs/issue-10/proposals/gate-a-plus-remediation.md:89-93`): "`gate_bash_write_targets`
is adopted defensively even though none of the 5 gates currently match
`Bash`-tool writes." Phase-2 execution wrote the Bash-handling *code* and a
direct-invocation regression test for it (`tests/batna-zopa-tests.sh:167-171`
pipes a synthetic `{"tool_name":"Bash",...}` payload straight into the gate
script) but never added `Bash` to the `hooks.json` matcher, so in a real
Claude Code session a `Bash echo >> docs/issue-N/proposals/x.md` command
never reaches this code at all — the tests exercise a branch the live
wiring cannot reach. This is the "Bash matcher gap / dead branch."

No gate script contains any `NotebookEdit`-specific branch (grep for
`NotebookEdit` inside `*/hooks/*.sh` returns nothing), and no `hooks.json`
matcher lists `NotebookEdit` either — see Defect 4 (README exaggeration)
for why this is a documentation mismatch, not merely a missing-matcher
mismatch.

## Defect 2 — verdict fall-through, no default arm (potential fail-open)

Every gate's Python payload prints a `verdict` string on stdout, which the
surrounding shell dispatches with a `case "$verdict" in ... esac` that has
**no catch-all `*)` arm**, followed by an unconditional `gate_allow` after
the `esac`:

- `strategic-fit-gate/hooks/strategic-fit-gate.sh:195-207` — case handles
  `DENY_NO_FIT`/`DENY_NO_COMPOUNDING_VALUE`/`DENY_ORDER` only (no `PASS`
  arm at all); any other verdict string (a `PASS`, or anything unexpected —
  a Python traceback fragment, a truncated print, a future verdict name
  typo'd during a later edit) falls through the case untouched and reaches
  line 207's bare `gate_allow`.
- `batna-zopa/hooks/batna-zopa-gate.sh:223-235` — same shape: 3 `DENY_*`
  arms, no `PASS` arm, unconditional `gate_allow` at line 235.
- `term-sheet-structure/hooks/term-sheet-structure-gate.sh` and
  `evidence-discipline/hooks/evidence-discipline-gate.sh` — same pattern
  (`esac` immediately followed by a bare `gate_allow`, confirmed by grep
  sweep on both files).
- `multi-axis-scoring/hooks/multi-axis-scoring-gate.sh:186-198` differs
  slightly: it has a `PASS) gate_allow ;;` arm inside the case, but still
  ends with a second, unconditional `gate_allow` at line 198 outside the
  `esac` — dead code on the `PASS` path (already exited by line 190), but
  live fallback for anything the case didn't match.

Net effect across all 5: today, correctness rests entirely on the Python
payload's verdict string always being one of the finitely many strings the
shell `case` recognizes. Any drift (a refactor renames a `DENY_*` constant
in the Python heredoc without updating the shell `case`, a crash mid-print
that still exits 0, stray output before the verdict line) resolves to
silent `gate_allow` rather than a fail-closed deny. This is the issue's
"verdict fall-through 잠재 fail-open."

## Defect 3 — ZOPA keyword opt-in residual

`batna-zopa/hooks/batna-zopa-gate.sh:188-219` (Python payload): the ZOPA
check is gated entirely behind `counterpart_para_idx is not None`
(line 206) — it only runs `if` the document already contains a
counterpart-position claim (a heading matching
`counterpart|상대방|저쪽|카운터파트`, or a paragraph pairing a counterpart
noun with a position/ask verb, lines 190-204). A phase-1 proposal or
phase-2 record that never discusses the counterpart's position at all
skips the ZOPA requirement entirely and reaches `print("PASS")` at
line 220 provided BATNA passed. This matches the issue-10 proposal's own
design intent verbatim
(`docs/issue-10/proposals/gate-a-plus-remediation.md:101-117`: "requires a
ZOPA claim... Either hit requires a ZOPA section to also be present") —
it was built this way on purpose, as an upgrade from pure substring
matching, not introduced by accident. The residual gap the re-audit is
flagging: BATNA/ZOPA negotiation doctrine (this gate's own stated
methodology, per `partnerships-bd/.claude-plugin/plugin.json`'s
description) treats "what's the other side's likely position" as
something a real deal proposal should always address, not something that
becomes checkable only once the author happens to mention it — the
"opt-in" framing describes a document that omits counterpart discussion
altogether, which currently sails through with no ZOPA finding at all
rather than being flagged as itself a gap.

## Defect 4 — README NotebookEdit overstatement

`README.md:54-60`:

```
Each gate references core canon `core/hooks/lib/gate-lib.sh` +
`gate-lib.py` (issue-72, `docs/handbooks/gate-house-standard.md`) for its
fail-closed trap, kill-switch check, path normalization, and Write/Edit/
MultiEdit/NotebookEdit reconstruction — sourced via
`${CLAUDE_PLUGIN_ROOT_CORE:-...}/hooks/lib/gate-lib.sh`, never
reimplemented locally.
```

This claims all 5 gates get "Write/Edit/MultiEdit/**NotebookEdit**
reconstruction" from core canon. Two separate problems:

1. No `hooks.json` in this repo has `NotebookEdit` in its matcher (grep
   sweep above), so no gate here is ever invoked for a `NotebookEdit` tool
   call in practice — the capability core's library exposes
   (`gate-lib.py:146-151`) is never wired up on this repo's side.
2. Even if it were wired up, core's own reconstruction for `NotebookEdit`
   is explicitly partial, not full-document reconstruction — the docstring
   at `gate-lib.py:104-113` states it returns only "the edited cell's new
   source... not... a single text blob," which is a materially different
   guarantee than the "Write/Edit/MultiEdit/NotebookEdit reconstruction"
   phrasing implies (that phrasing reads as uniform, full-document
   reconstruction across all four tools).

README overstates a capability that is neither wired into this repo's
matchers nor, on core's side, equivalent in shape to the other three tools.

## Additional finding beyond the issue's named list — unguarded source line

All 5 gate scripts source `gate-lib.sh` **without** the `||` guard core's
own doc comment (`core/hooks/lib/gate-lib.sh:11-18`) mandates:

- `batna-zopa/hooks/batna-zopa-gate.sh:8`
- `strategic-fit-gate/hooks/strategic-fit-gate.sh:8`
- `term-sheet-structure/hooks/term-sheet-structure-gate.sh:8`
- `evidence-discipline/hooks/evidence-discipline-gate.sh:8`
- `multi-axis-scoring/hooks/multi-axis-scoring-gate.sh:8`

All read:
`. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/gate-lib.sh"`
— no trailing `|| { echo ...; exit 2; }`. This is precisely the shape
`core/hooks/tests/compliance-check.sh:52-58` is built to detect and flag as
a violation, and precisely the shape `core/hooks/tests/run-gate-lib-tests.sh`'s
`missing-core` group (line 230 `mark missing-core`) regression-tests against
core's own `record-fields-gate.sh`. This repo's 5 gates were never checked
against either.

This directly explains why "missing-core" test coverage is entirely absent
from this repo's own suite (next section): a missing-core test written
against the *current* gate scripts would likely fail, since the resolved
core dir not existing does not `exit 2` at line 8 — the script falls
through into `gate_trap_fail_closed`/`set -uo pipefail`/`gate_kill_switch_active`
with those functions undefined, and Claude Code's own hook-exit-code
contract (`core/hooks/lib/gate-lib.sh:36-40`'s comment: "any hook exit
other than 0/2 is non-blocking (fail-open)") means an unhandled non-0/2
exit from the whole script is treated as an allow, not a deny.

## Missing-core test-case audit

`tests/parse-check.sh`, `tests/run-gate-tests.sh`,
`tests/deny-only-check.sh`, and each `tests/<plugin>-gate-tests.sh` file
(`batna-zopa-tests.sh`, `evidence-discipline-tests.sh`,
`multi-axis-scoring-tests.sh`, `strategic-fit-gate-tests.sh`,
`term-sheet-structure-tests.sh`) were grepped for `missing.core`,
`CLAUDE_PLUGIN_ROOT_CORE`, and `no-such-core` — **zero matches** in any
file. No missing-core test case exists anywhere in this repo's own suite.
`tests/run-gate-tests.sh:8-11` aggregates exactly the 5
`<plugin>-tests.sh` files above and nothing else, so there is no separate
suite file where such a case might live instead.

By contrast, `tests/batna-zopa-tests.sh:167-171` does have a `Bash`-tool
regression case (item 6 of issue-10's mandatory list,
`docs/issue-10/proposals/gate-a-plus-remediation.md:155-157`), confirming
the other five issue-10-mandated cases (replace_all Edit, MultiEdit mixed
replace_all, malformed JSON, kill-switch typo, absolute/`./`-prefixed
path) were carried through — missing-core specifically was never on
issue-10's own mandatory list (that proposal's list, lines 137-157, has 6
items and none is missing-core) and remains the one gap.

## README / manifest ghost-reference audit

- `README.md` Layout section (lines 20-28) and Methodology plugins section
  (lines 38-60) were checked line-by-line against the actual directory tree
  (`find` for `plugin.json`, `hooks.json`, `directive.sh`,
  `record-fields.config`, `warrant-hunter.md`, `deliverable-shapes.md`,
  `docs/specs/approvers.md`, `multi-axis-scoring/reference/axes.md`) — every
  named file/path exists. Issue-10's own remediation
  (`docs/issue-10/proposals/gate-a-plus-remediation.md:170-176`) already
  removed the three ghost files this repo previously listed
  (`record-fields-gate.sh`, `trailer-gate.sh`, `handbook-trigger-gate.sh` —
  confirmed absent from the current README and from
  `partnerships-bd/hooks/`, which contains only `directive.sh`,
  `hooks.json`, `record-fields.config`).
- All 6 `.claude-plugin/plugin.json` files (`partnerships-bd` and the 5
  methodology plugins) and the top-level `.claude-plugin/marketplace.json`
  (`name: tokenmaxxxer-partnerships-bd`, 6 plugin entries) were read in
  full: plugin names, `source` paths, and descriptions are internally
  consistent with the actual directory names and with each other (e.g.
  `strategic-fit-gate`'s description references the exact chain order
  `strategic-fit-gate -> multi-axis-scoring -> batna-zopa ->
  evidence-discipline` that `README.md:51` also states). No stale role name
  or dangling `source` path found in any manifest.
- No occurrence of an old/retired role name (e.g. a pre-issue-160 role
  name, or any name other than `partnerships-bd`) was found in `README.md`
  or any `plugin.json`/`marketplace.json` via grep.
- Conclusion: the README/manifest "ghost file" defect issue-10 fixed stays
  fixed; the residual README problem the re-audit is pointing at is the
  NotebookEdit overstatement (Defect 4 above), not a reintroduced ghost
  file or stale role name. The issue's requirement #4 ("README/manifest
  옛 역할명/유령 파일 잔재 0") is a standing invariant that phase-2 should
  re-verify holds after any edit, not a new violation found in this survey.

## Files read for this survey

- `README.md` (full)
- `partnerships-bd/.claude-plugin/plugin.json`,
  `strategic-fit-gate/.claude-plugin/plugin.json`,
  `multi-axis-scoring/.claude-plugin/plugin.json`,
  `batna-zopa/.claude-plugin/plugin.json`,
  `evidence-discipline/.claude-plugin/plugin.json`,
  `term-sheet-structure/.claude-plugin/plugin.json`,
  `.claude-plugin/marketplace.json`
- `{strategic-fit-gate,multi-axis-scoring,batna-zopa,evidence-discipline,term-sheet-structure}/hooks/hooks.json`
- `{strategic-fit-gate,multi-axis-scoring,batna-zopa,evidence-discipline,term-sheet-structure}/hooks/*-gate.sh` (full)
- `tests/run-gate-tests.sh`, `tests/parse-check.sh`, `tests/batna-zopa-tests.sh`
  (grep sweep for missing-core / Bash coverage on all 5 `*-tests.sh`)
- `partnerships-bd/hooks/record-fields.config`, `partnerships-bd/hooks/hooks.json`
- `docs/issue-10/proposals/gate-a-plus-remediation.md` (prior phase-1 proposal, for baseline)
- Core checkout (env `CLAUDE_PLUGIN_ROOT_CORE`):
  `core/hooks/lib/gate-lib.sh` (full), `core/hooks/lib/gate-lib.py` (full),
  `core/hooks/tests/run-gate-lib-tests.sh` (grep for missing-core group),
  `core/hooks/tests/compliance-check.sh` (grep for guard-detection reason string)
