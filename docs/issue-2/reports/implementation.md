# Phase-2 record — issue-2

Subject: issue-2. Executed the core-canon-reference conversion per
`docs/issue-2/proposals/core-canon-conversion.md`, approved via
`APPROVE issue-2/implementation`.

## What was done

Converted this role's rulebook to reference core canon instead of vendoring
local copies: replaced `agents/warrant-hunter.md` with a short reference to
core's `warrant/` plugin, deleted the three role-agnostic gate copies and
their `hooks.json` registrations, restubbed `directive.sh` to source and
call core's `core_role_directive`, preserved this role's real
`REQUIRED_FIELDS` divergence in an explicit config file, and ran
`stub-check.sh` to confirm the result.

## Why

Core issues #63 and #66 landed a single canon for the hunt-agent contract,
the three role-agnostic gates, and the directive boilerplate function.
This repo's issue-2 requires converting to reference that canon (deleting
duplicated copies) before this rulebook's own maturation-issue phase 2, per
the ordering constraint in the issue text and the phase-1 proposal.

## Upstream basis

- Core issue #63 (`warrant/` plugin canon).
- Core issue #66 (role-agnostic gate canon + `CLAUDE_ROLE`-injected
  registration + `core/hooks/lib/role-directive.sh` + `stub-check.sh`).
- This repo's phase-1 survey and proposal
  (`docs/issue-2/reports/implementation/survey.md`,
  `docs/issue-2/proposals/core-canon-conversion.md`).
- Approval: issue comment `APPROVE issue-2/implementation` by
  `JiwonJung94` (approvers.md account).

## loop_state

loop_state: done

## Open findings

None.

## Actions taken

1. `partnerships-bd/agents/warrant-hunter.md` — replaced the full copy of
   the hunt-agent contract with a short reference to core's `warrant/`
   plugin (core issue #63), keeping only the mandate line, the hand-off
   line, and the note that this role's stance rotation set is still to be
   enumerated.
2. Deleted `trailer-gate.sh`, `record-fields-gate.sh`,
   `handbook-trigger-gate.sh` and dropped their three `PreToolUse` entries
   from `hooks.json` (core issue #66's own registration now fires them).
   The `SessionStart` → `directive.sh` entry was kept.
3. `directive.sh` replaced with a stub: sources
   `core/hooks/lib/role-directive.sh`, sets four role-unique variables,
   and calls `core_role_directive` once. Verified against the actual core
   file (found at the harness's cached core-hooks checkout) that the
   function signature is `core_role_directive <you_decide> <use_when>
   <produces> <hand_off>` — four positional args, not the
   config-object shape the phase-1 proposal left as an open assumption.
   `WRITE_SCOPE` and `BOUNDARY CASE`, which have no slot in core's
   template, are folded into the `produces`/`hand_off` argument strings
   (each a single-line `$'...'` assignment with embedded `\n`) so the
   stub still contains only the source line, plain variable assignments,
   and the one call — nothing else, per stub-check's structural cap.
4. This role's actual per-role divergence — `REQUIRED_FIELDS =
   ["deal-structure-verdict", "term-sheet-outline"]` — preserved
   explicitly in new `partnerships-bd/hooks/record-fields.config`, since
   core's own record-fields-gate.sh source was not available in this tree
   to confirm its real per-role config-read convention. Flagged in that
   file as an assumption pending confirmation against core's actual
   mechanism.
5. Ran `core/hooks/tests/stub-check.sh` against this role's `hooks/` tree
   (found in the harness's cached core-hooks checkout, not in this repo):

   ```
   stub-check: ok — no vendored 'trailer-gate.sh' under partnerships-bd
   stub-check: ok — no vendored 'record-fields-gate.sh' under partnerships-bd
   stub-check: ok — no vendored 'handbook-trigger-gate.sh' under partnerships-bd
   stub-check: ok — no vendored 'parse-check.sh' under partnerships-bd
   stub-check: ok — partnerships-bd/hooks/directive.sh is a role-directive stub
   ```

   All checks pass (`rc=0`).

## Open item carried forward

`record-fields.config`'s format is unverified against core's real gate
convention (core's promoted `record-fields-gate.sh` source was not present
alongside the two gate files and the `role-directive.sh`/`stub-check.sh`
files that were available).

## Next steps

Whoever lands core's registration side confirms/renames
`partnerships-bd/hooks/record-fields.config` to match core's actual
per-role config-read convention once core's `record-fields-gate.sh` source
is available for inspection.

## Open-finding resolution path

Not this role's job to resolve directly — flagged for the core-issue-66
registration follow-up to confirm against the real gate source; no action
blocks this issue's own five conversion items, all of which are complete.
