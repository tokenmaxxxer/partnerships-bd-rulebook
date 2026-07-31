# Phase-2 record — issue-1

Subject: issue-1. Phase-2 execution of the approved proposal
`docs/issue-1/proposals/rulebook-maturation.md`, section (d) items 1-3.

## What was done

Reflected the approved proposal into the plugin: extended
`directive.sh`'s `PRODUCES` line with a pointer to the new required-shape
reference, created `partnerships-bd/reference/deliverable-shapes.md` as
the canonical required-shape spec, and extended
`partnerships-bd/hooks/record-fields.config` with a sub-section
requirement for `term-sheet-outline`, preserving the existing
`REQUIRED_FIELDS` line.

## Why

The proposal was approved for execution; section (d) items 1-3 are the
concrete phase-2 plugin changes it specifies (item 4 is this record
file; item 5 is a documented convention only, no gate exists).

## Upstream basis

- `docs/issue-1/proposals/rulebook-maturation.md` (approved), sections
  (a), (b), (d).
- `docs/issue-1/reports/partnerships-bd/scout-brief.md` and
  `docs/issue-1/reports/partnerships-bd/survey.md` (phase-1 basis for
  the proposal).

## deal-structure-verdict

N/A — this deliverable is a plugin/rulebook change, not a partnership
deal; there is no weighted-axis derivation to show. This record
demonstrates the new required shape by reference:
`partnerships-bd/reference/deliverable-shapes.md` is now the
authoritative spec for this field going forward.

## term-sheet-outline

N/A — same reason as above, no deal is being structured. Authoritative
sub-section list is `partnerships-bd/reference/deliverable-shapes.md`.

## loop_state

loop_state: done

## Actions taken

1. `partnerships-bd/hooks/directive.sh` — `PRODUCES` heredoc now ends
   with "(see reference/deliverable-shapes.md for required shape)",
   one-line pointer, rest of the file untouched.
2. `partnerships-bd/reference/deliverable-shapes.md` — new file, the
   canonical required-shape spec for `deal-structure-verdict` (weighted
   multi-axis table + BATNA/ZOPA) and `term-sheet-outline` (seven named
   sub-sections), plus a brief note on the phase-1 convention from
   proposal item (d)(5).
3. `partnerships-bd/hooks/record-fields.config` — kept
   `REQUIRED_FIELDS="deal-structure-verdict,term-sheet-outline"`
   unchanged, added `REQUIRED_SUBSECTIONS_term_sheet_outline` below it
   with its own ASSUMPTION comment (mirrors the file's existing
   ASSUMPTION style), flagging this as new gate surface not yet
   confirmed against core's promoted gate script.

This satisfies proposal section (d) items 1-3.

## Open findings

None. Item 3's sub-section gate remains unconfirmed against core's
actual gate-read mechanism (per proposal item (d)(3) and (d)(5)); this
is a documented, known-open assumption, not a defect in this phase-2
work — enforced by human PR review until core ships a sub-section hook.

## Next steps

Whoever confirms core's actual per-role gate-read convention renames
or reformats `REQUIRED_SUBSECTIONS_term_sheet_outline` to match it if
needed; until then, human PR review enforces the sub-section list in
`partnerships-bd/reference/deliverable-shapes.md`.

## Open-finding-resolution-path

Not this role's job to resolve directly — flagged for whichever future
work confirms core's promoted gate script's real per-role config-read
convention. No action here blocks proposal section (d) items 1-3, all
of which are complete.
