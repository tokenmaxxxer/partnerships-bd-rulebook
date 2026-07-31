# Proposal — convert to core canon references (issue-2)

Subject: issue-2. Phase 1 proposal only — describes the phase-2 change,
does not execute it. Based on the survey at
`docs/issue-2/reports/implementation/survey.md`.

## Summary

Core has landed a single canon for three things this rulebook currently
carries as full local copies: the warrant-hunter agent (core issue #63),
the three role-agnostic gates (core issue #66), and a shared directive
boilerplate function. Convert this role's rulebook to reference that
canon and delete the copies, while preserving the parts of each file that
are genuinely `partnerships-bd`-specific.

## Per-item plan

1. **`partnerships-bd/agents/warrant-hunter.md`** — remove the file
   content that duplicates the generic hunt-agent contract (mandate
   framing, "adapted from implementation-rulebook" preamble, scope
   boilerplate) and replace with a short reference to the core
   `warrant/` plugin, keeping only:
   - the decision boundary line: 파트너십이 구조적으로 성립하는가
   - the hand-off line: 법적 계약 검토는 → legal-compliance
   - a note that this role's stance rotation set is still to be
     enumerated (this was already marked a skeleton pre-conversion; the
     conversion doesn't resolve it, just relocates the surrounding
     boilerplate)

2. **Gate copies** (`trailer-gate.sh`, `record-fields-gate.sh`,
   `handbook-trigger-gate.sh`) — delete all three files outright, and
   drop their three `PreToolUse` entries from `hooks/hooks.json`. Core's
   own hook registration (core issue #66, `CLAUDE_ROLE`-injected) takes
   over enforcement; nothing in this role's `hooks.json` should
   duplicate it. The `SessionStart` → `directive.sh` entry stays, since
   the directive itself is not being deleted, only reshaped (item 3).

3. **`directive.sh`** — replace the current standalone heredoc script
   with a stub: source `core/hooks/lib/role-directive.sh`, call
   `core_role_directive` with this role's identity/kill-switch env var
   (`PARTNERSHIPS_BD_CYCLE_OFF`) and role name (`partnerships-bd`), and
   pass only the role-unique fields as arguments/config rather than
   printing the whole heredoc locally:
   - decides: 파트너십이 구조적으로 성립하는가
   - use_when: 제휴/BD 딜 구조가 걸릴 때
   - produces: deal structure verdict, term sheet outline
   - write_scope: `[]`
   - hand-off: 법적 계약 검토는 → legal-compliance
   - record path: `docs/issue-<n>/reports/partnerships-bd.md`

   Exact call signature is an assumption pending phase-2 access to the
   real `core_role_directive` definition (see survey unknowns) — the
   phase-2 implementer confirms the function's actual parameter shape
   before writing the stub; this proposal fixes only which fields must
   surface, not the call syntax.

4. **Preserve real per-role divergence via explicit config** — this
   role's actual divergence from the deleted `record-fields-gate.sh`
   copy is its `REQUIRED_FIELDS = ["deal-structure-verdict",
   "term-sheet-outline"]` list (there is no terminal-`loop_state`
   divergence found anywhere in this rulebook, unlike the issue's named
   example). Phase 2 must carry this list forward as whatever explicit
   per-role config core's gate registration reads (analogous role to
   `RECORD_FIELDS_TERMINAL_STATES` in the issue's example, but for
   required fields, not terminal states) — not drop it silently when
   the local gate file disappears, since dropping it would mean nothing
   enforces this role's own `produces` contract.

5. **Verify against `core/hooks/tests/stub-check.sh`** and record the
   pass in `docs/issue-2/reports/partnerships-bd.md` once phase 2 opens.
   Not run in phase 1 — the script isn't present in this tree and needs
   the phase-2 environment where core is available alongside this repo.

## Ordering constraint (from issue)

This conversion must land before this repo's "rulebook maturation" issue
phase 2. No action needed in phase 1 beyond noting it; phase 2 execution
order is a phase-2 concern.

## Out of scope for this proposal

- Enumerating the warrant-hunter stance rotation set (pre-existing
  skeleton gap, not created or resolved by this conversion).
- Hardening `handbook-trigger-gate.sh`'s placeholder logic — it is being
  deleted outright per item 2, not hardened then deleted.
