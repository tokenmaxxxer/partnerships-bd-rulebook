# Phase-1 survey — issue-2

Subject: issue-2. Scope: current-state inventory of this rulebook's
warrant-hunter / gate copies and directive.sh, ahead of proposing the
core-canon-reference conversion.

## Scout skip record

Scouting skipped. Reason: this task has no open design-comparison
decision — the issue specifies the exact five conversion actions against
a already-landed core canon (core issues #63/#66); the only work is
inventorying this repo's copies and mapping each onto the named core
surface. No external field to benchmark against.

## Inventory (this repo only — core canon lives in a separate repo/plugin
not present in this tree; its shape is taken from the issue text and from
this role's own files' internal references to it)

| File | Current role | Issue action | Role-unique content to preserve |
|---|---|---|---|
| `partnerships-bd/agents/warrant-hunter.md` | Full copy of the hunt-agent doc, adapted from implementation-rulebook's copy | (1) remove; replace with core-canon reference | The mandate line ("파트너십이 구조적으로 성립하는가"), the hand-off line ("법적 계약 검토는 → legal-compliance"), and the note that stance set is a to-be-enumerated skeleton |
| `partnerships-bd/hooks/trailer-gate.sh` | Full copy of trailer-gate logic, already noted in its own header as "role-agnostic" logic with only the role name substituted | (2) remove file + its `hooks.json` registration | none — file states its own logic is role-agnostic; nothing here is partnerships-bd-specific except the role name string used in `deny()` messages and `PARTNERSHIPS_BD_CYCLE_OFF` |
| `partnerships-bd/hooks/record-fields-gate.sh` | Full copy of record-fields-gate logic, with `REQUIRED_FIELDS = ["deal-structure-verdict", "term-sheet-outline"]` hardcoded | (2) remove file + its `hooks.json` registration | The `REQUIRED_FIELDS` list itself is role-unique (this role's actual `produces`) — issue action (4) says preserve real per-role differences via explicit config (`RECORD_FIELDS_TERMINAL_STATES` is the named example for terminal states; the analogous need here is the required-fields list) |
| `partnerships-bd/hooks/handbook-trigger-gate.sh` | Full copy, currently a placeholder (`exit 0` — TODO before load-bearing) | (2) remove file + its `hooks.json` registration | none identified — file is an unhardened placeholder; no role-specific logic exists yet to preserve |
| `partnerships-bd/hooks/directive.sh` | Standalone script: kill-switch trap boilerplate + heredoc printing the full role directive (decides/use_when/produces/write_scope/hand-off/boundary-case/record path) | (3) replace with stub sourcing `core/hooks/lib/role-directive.sh`'s `core_role_directive` function, calling it, and keeping only the role-unique body | decides: "파트너십이 구조적으로 성립하는가"; use_when: "제휴/BD 딜 구조가 걸릴 때"; produces: "deal structure verdict, term sheet outline"; write_scope: `[]`; hand-off: "법적 계약 검토는 → legal-compliance"; record path: `docs/issue-<n>/reports/partnerships-bd.md` |
| `partnerships-bd/hooks/hooks.json` | Registers all three gates as `PreToolUse` hooks plus `directive.sh` as `SessionStart` | (2) drop the three gate registrations (core's own registration takes over per core issue #66); keep the `SessionStart` → `directive.sh` entry, since the role directive itself is not being removed, only reshaped | — |

## Unknowns / open questions for the proposal

- The exact path and calling convention of `core/hooks/lib/role-directive.sh`'s
  `core_role_directive` function is stated in the issue but not verifiable
  from this repo (core repo not vendored here). The proposal must describe
  the stub shape assuming the issue's own description literally, and flag
  this as an assumption the phase-2 implementer must confirm against the
  actual core file before writing the stub.
- `core/hooks/tests/stub-check.sh` (issue action 5) is likewise not present
  in this tree — its existence and pass/fail contract can only be confirmed
  once core is available in the phase-2 environment (e.g. as a sibling
  plugin/checkout). Recorded here as a phase-2 dependency, not resolved in
  phase 1.
- No role-level difference in terminal `loop_state` values was found in
  any file surveyed (issue action 4's named example concerns
  `RECORD_FIELDS_TERMINAL_STATES`, which doesn't map cleanly onto this
  role's actual per-role divergence, which is its `REQUIRED_FIELDS` list
  in record-fields-gate.sh, not a terminal-states set). Proposal treats
  the config knob generically: whatever this role's real per-role
  divergence is (here: required record fields), it must survive as an
  explicit override, not be silently dropped when the gate copy is
  deleted.
