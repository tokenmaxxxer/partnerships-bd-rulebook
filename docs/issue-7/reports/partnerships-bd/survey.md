# Current-state survey — issue-7 phase 1 (partnerships-bd)

## Write surfaces this role owns

- `docs/issue-<n>/proposals/*.md` — phase-1 proposals.
- `docs/issue-<n>/reports/partnerships-bd.md` — phase-2 record (this
  role's only phase-2 write surface per contract v3 s19; `WRITE_SCOPE`
  in `directive.sh` is `[]`, i.e. no additional src/ write scope).

## Plugin tree as it exists today

```
partnerships-bd/
  .claude-plugin/plugin.json      — single plugin entry
  hooks/
    hooks.json                    — one hook: SessionStart -> directive.sh
    directive.sh                  — sources core/hooks/lib/role-directive.sh,
                                     prints YOU_DECIDE/USE_WHEN/PRODUCES/HAND_OFF
    record-fields.config          — REQUIRED_FIELDS presence list (read by
                                     core's canon record-fields-gate.sh,
                                     not vendored here — canon-scripts.md
                                     compliant) + one documented-only
                                     REQUIRED_SUBSECTIONS_* line with no
                                     confirmed reader
  reference/
    deliverable-shapes.md         — prose spec of required derivation
                                     components (multi-axis table, BATNA/
                                     ZOPA) and required sub-sections
                                     (7 named, term-sheet-outline) —
                                     documentation only, not gate-enforced
  agents/
    warrant-hunter.md             — rotating stance-check agent (contract
                                     v3 mechanism, not a methodology plugin)
```

`.claude-plugin/marketplace.json` (repo root) lists exactly one plugin:
`partnerships-bd`. No companion plugins exist.

## What issue-1 phase 2 already adopted (the methodology source)

Per `docs/issue-1/proposals/rulebook-maturation.md` parts (a)/(b),
fixed in `partnerships-bd/reference/deliverable-shapes.md`:

1. Strategic/ICP-fit + compounding-value opening statement (phase-1
   proposal ordering rule).
2. Weighted multi-axis evaluation table (6 named axes, weight+score per
   axis, summing to `deal-structure-verdict`).
3. BATNA statement + ZOPA estimate (negotiation-theory derivation of the
   same verdict).
4. Stage declaration (non-binding vs binding-terms-ready) + citation
   discipline (evidence per claim, two claim categories).
5. Term-sheet 7-subsection structure for `term-sheet-outline`
   (purpose, roles, terms, governance, KPIs, dispute-resolution, exit —
   exit non-optional, governance/KPIs kept distinct).

**None of these five are mechanically enforced.** They exist only as
prose in `deliverable-shapes.md` and as a `record-fields.config` line
whose own header flags it as an unconfirmed assumption about what core's
gate reads. A write to either surface today passes with any string in
the required fields — the exact gap issue-7 opens against.

## Gap vs issue-7's corrected requirement

The issue's requirement-correction comment specifies: independent
plugin per methodology (freelunch/scout-level completeness), phase-1
and phase-2 norms each expressed as a plugin *combination*, each plugin
self-contained (directive/gate/agent/test as applicable) and registered
in `marketplace.json`, and the proposal must carry a plugin
list (name / methodology owned / components / combination role).

Current state has zero of: per-methodology plugin separation, gates,
gate tests, or a multi-plugin marketplace.json entry for this role.

## Constraints re-confirmed for phase 2 (not executed here)

- Canon scripts referenced only, never copied (`canon-scripts.md`) —
  any new gate script here must be role-methodology-specific, not a
  second copy of a core canon file.
- Role boundary / `WRITE_SCOPE: []` unchanged — no plugin here gets a
  src/ write scope.
- `docs/issue-1/proposals/rulebook-maturation.md` is the adoption-basis
  source of record; new plugins encode its parts (a)/(b), they do not
  re-derive new methodology.
</content>
