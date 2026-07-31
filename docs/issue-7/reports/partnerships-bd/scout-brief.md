# Scout brief — issue-7 phase 1 (partnerships-bd)

Mode: batched-sequential file reads (local repo tree, no web search
needed — the exemplar lives in sibling checkouts of this same
marketplace). 2 stages: (1) sweep across sibling rulebooks for a
multi-plugin split precedent + the pricing-rulebook methodology-gate
the issue names; (2) one deepening read of the winning exemplar's
plugin.json/hooks.json shapes. Elapsed well under budget.

## Exemplar found: implementation-rulebook (4 plugins, one marketplace)

`~/tokenmaxxxer/rulebooks/implementation-rulebook/.claude-plugin/marketplace.json`
lists `coding` (generation-layer role directive) + three **independent,
self-contained** companion plugins, each owning exactly one methodology
and cross-referencing the others in its own `description`:

- `blueprint` — archetype classification methodology: CLI + skill, no
  gate machinery.
- `no-mock` — production-runnable-structure methodology: **pure
  direction**, explicitly "no gates, no sniffers, no verification
  passes" (own plugin.json).
- `no-footgun` — threat-pattern steering: direction + "surface-gated,
  cascading custom rules, zero review passes."

Each plugin: own `.claude-plugin/plugin.json` (name/version/description
naming its one methodology + companions), own `hooks/`, own
`hooks/tests/`. No shared plugin holds two methodologies.

## Exemplar found: pricing-rulebook methodology-gate (issue text's named reference)

`~/tokenmaxxxer/rulebooks/pricing-rulebook/pricing/hooks/methodology-gate.sh`
— single-plugin PreToolUse gate on Write/Edit/MultiEdit, scoped by regex
to `docs/issue-<n>/proposals/*pricing*.md` and
`docs/issue-<n>/reports/pricing.md`, checking presence of named required
elements (method named, gate-check result, labeled numbers, residual
list) via python3 text-scan on the resulting content, fail-closed on
internal error and on unparseable payload. This is the MECHANISM shape
to reuse per-plugin, not the one-big-gate-for-everything shape (issue-7's
corrected requirement is one gate per methodology, not one gate for the
whole rulebook).

## Must-bes (Kano) for this deliverable

- Each adopted methodology (per `docs/issue-1/proposals/rulebook-maturation.md`
  parts (a)/(b)) becomes its own plugin: own directive + own gate +
  registration in `.claude-plugin/marketplace.json`.
- Phase-1 norm and phase-2 norm are each a stated COMBINATION of
  plugins — not a single merged gate.
- Canon scripts referenced only (`docs/handbooks/canon-scripts.md` in
  core) — no copying core's `record-fields-gate.sh` pattern verbatim
  into a rulebook tree; each new gate here is role/methodology-specific,
  not a core canon file.

## Adopt / skip

- **Adopt**: per-methodology plugin split (implementation-rulebook
  precedent) + per-plugin fail-closed gate scoped by regex to this
  role's own write surfaces (pricing-rulebook precedent).
- **Skip**: a single mega-gate checking all methodologies at once (the
  issue comment explicitly corrects away from this — "단일 게이트/디렉티브
  심화가 아니라 플러그인 세트로").

## Gap line (current state vs field must-bes)

partnerships-bd currently has ONE plugin with a directive pointer
(directive.sh) and a documented-only shape reference
(deliverable-shapes.md) but **no gate at all** — record-fields.config
checks field *presence* via core's canon gate, not methodology
*derivation*. Missing entirely: (1) any per-methodology plugin
separation, (2) any gate enforcing multi-axis-table/BATNA-ZOPA/citation
discipline/term-sheet-subsections, (3) any marketplace.json plugin list
beyond the single `partnerships-bd` entry, (4) gate tests.

Sources:
- ~/tokenmaxxxer/rulebooks/implementation-rulebook/.claude-plugin/marketplace.json
- ~/tokenmaxxxer/rulebooks/implementation-rulebook/no-mock/.claude-plugin/plugin.json
- ~/tokenmaxxxer/rulebooks/implementation-rulebook/no-footgun/.claude-plugin/plugin.json
- ~/tokenmaxxxer/rulebooks/pricing-rulebook/pricing/hooks/methodology-gate.sh
- ~/tokenmaxxxer/tokenmaxxxer-core/core/docs/handbooks/canon-scripts.md
</content>
