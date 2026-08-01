# issue-10 phase-1 survey: current-state audit of partnerships-bd's gates

Scope: the 5 methodology-plugin gates (`strategic-fit-gate`, `multi-axis-scoring`,
`batna-zopa`, `evidence-discipline`, `term-sheet-structure`), each at
`<plugin>/hooks/<plugin>-gate.sh`, ~200-230 lines, structurally near-identical
(same audit found the same defects "전 게이트" — across all gates).

## Confirmed defects (matches issue #10's audit + core issue-72's own findings)

1. **deny() writes to stdout, not stderr.** Every gate's `deny()`:
   ```
   printf '{"hookSpecificOutput":{"permissionDecision":"deny","permissionDecisionReason":"%s"}}\n' "$1"
   exit 2
   ```
   e.g. `batna-zopa/hooks/batna-zopa-gate.sh:10-13`, same shape in
   `strategic-fit-gate`, `evidence-discipline`, `multi-axis-scoring`,
   `term-sheet-structure`. Core's `gate_deny` (gate-house-standard.md) writes
   to stderr only. stdout-JSON-on-exit-2 is not the protocol Claude Code
   reads a PreToolUse deny reason from — the reason is lost. Confirms the
   issue's claim ("사유 전부 유실, 전 게이트").

2. **Kill switches: one backwards, four merely narrow.**
   `strategic-fit-gate/hooks/strategic-fit-gate.sh:8-10`:
   ```
   case "${STRATEGIC_FIT_GATE_OFF:-}" in
     ""|0|false|no|off) : ;;
     *) exit 0 ;;
   esac
   ```
   This is the exact fail-open bug core's own audit (gate-house-standard.md
   "the two bugs this issue fixed", #1) found and fixed in core's canon: any
   unrecognized value (including a typo) disables the gate. The other four
   gates (`evidence-discipline`, `multi-axis-scoring`, `term-sheet-structure`,
   `batna-zopa`) use `[ "${X_GATE_OFF:-}" = "1" ]` — not backwards, but only
   recognizes `"1"`, silently ignoring `true`/`yes`/`on` as on-spellings, an
   inconsistency with the now-canon convention.

3. **No `realpath`, loose root resolution.** All 5 gates resolve root via
   `CLAUDE_PROJECT_DIR` -> `git rev-parse --show-toplevel` -> `cwd` fallback
   (e.g. `batna-zopa-gate.sh:58-65`), then do bare `${abs_path#"$root"/}"`
   string-strip — no `posixpath.normpath`-equivalent, no `./`-prefix
   collapsing, no symlink resolution. A `./docs/issue-N/...` or a
   double-slash path silently fails to match. Matches the issue's "루트
   검증 느슨·realpath 부재."

4. **`replace_all` ignored on every Edit/MultiEdit reconstruction.**
   `batna-zopa-gate.sh:130` (`Edit`) and `:156` (`MultiEdit`, per-edit loop)
   both hardcode `.replace(old_string, new_string, 1)` regardless of the
   real call's `replace_all` field. Same shape confirmed in the sibling
   gates. This is line-for-line the bug core's own `record-fields-gate.sh`
   had (gate-house-standard.md "bugs fixed" #2) before migrating to
   `gate_lib.gate_reconstruct_write`. No gate reconstructs `NotebookEdit`
   at all (not required by any of these 5 gates' write surface today, but
   `gate_reconstruct_write` covers it for free once adopted).

5. **ZOPA requires the literal word "counterpart," not a structural
   check.** `batna-zopa-gate.sh:201-204`:
   ```python
   if re.search(r"(?i)counterpart", text):
       if not re.search(r"(?i)zopa", text):
           print("DENY_NO_ZOPA")
   ```
   A proposal that discusses the other side's position without the exact
   token "counterpart" (e.g. "상대방", "저쪽 요구", "the other party") never
   triggers the ZOPA requirement at all — semantically the gate is a
   substring/word check, not a judgment of whether the text is actually
   making a counterpart-position argument. Same substring-only shape
   elsewhere: BATNA's "substance" check (`:180-194`) is stronger (windowed
   context + stripped-length threshold) but still purely lexical, no
   section/structure awareness.

## README ghost-file / drift check

`README.md`'s Layout section lists, under `partnerships-bd/hooks/`:
`record-fields-gate.sh`, `trailer-gate.sh`, `handbook-trigger-gate.sh`.
Actual `partnerships-bd/hooks/` contents: `directive.sh`, `hooks.json`,
`record-fields.config` only — none of the three listed gate scripts exist in
this repo (they are core canon files, invoked by path from
`core/hooks/*.sh`, never vendored per `canon-scripts.md`'s reference-not-copy
rule — the README is describing core's files as if they were this
plugin's own). The 5 methodology plugins' kill-switch env vars
(`STRATEGIC_FIT_GATE_OFF`, `MULTI_AXIS_SCORING_GATE_OFF`, `BATNA_ZOPA_GATE_OFF`,
`EVIDENCE_DISCIPLINE_GATE_OFF`, `TERM_SHEET_STRUCTURE_GATE_OFF`) are not
documented in README at all.

## What already exists to reuse

- `core/hooks/lib/gate-lib.sh` + `core/hooks/lib/gate-lib.py` (issue-72,
  landed): `gate_trap_fail_closed`, `gate_kill_switch_active`, `gate_deny`/
  `gate_allow` (stderr-only), `gate_parse_json_or_deny`,
  `gate_normalize_path`, `gate_reconstruct_write` (Write/Edit/MultiEdit/
  NotebookEdit, replace_all-honoring), `gate_bash_write_targets`.
- `core/hooks/tests/run-gate-lib-tests.sh` — the mandatory 6-case suite
  (replace_all-true-multi-occurrence Edit, mixed-replace_all MultiEdit,
  malformed JSON, unrecognized-kill-switch-value-stays-active, absolute +
  `./`-prefixed path match, Bash-tool write-target match).
- `core/hooks/tests/compliance-check.sh` — flags hand-rolled kill-switch
  reads and hand-rolled `.replace()` reconstruction; this repo's own
  compliance-check run against its 5 gates would flag all 5 (defects 2-4
  above are exactly what it detects).
- `directive.sh` in every plugin here already sources core via
  `${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/role-directive.sh`
  — the reference-path idiom the migration should reuse verbatim for
  `gate-lib.sh`/`gate-lib.py`.
- `tests/deny-only-check.sh` (already in this repo) asserts no gate emits
  `permissionDecision: allow` and probes an empty-write refusal across all
  6 plugins — stays valid post-migration, not itself a target of the fix.

## Scouting note (scout-directive)

This is prescribed-standard adoption, not an open product/design-direction
decision: the issue's precondition names a single landed core canon
(`core/hooks/lib/gate-lib.sh`, `docs/handbooks/gate-house-standard.md`) as
the exact interface to reference-adopt, with "자체 재구현 금지" (no
independent reimplementation) as an explicit constraint. That canon file
IS the best-in-class comparable system for this deliverable — reading it in
full (done above, under "What already exists to reuse") is the sweep; there
is no second exemplar to compare against, and no external market angle
applies to an internal gate-migration task. Skip condition met: "the spec
literally leaves no design decision open" for the *library choice* — the
remaining design decisions (how to phase the migration, how to design the
semantic-check upgrade beyond core's scope) are the proposal's own content,
addressed there directly rather than via external scouting.
