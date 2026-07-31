#!/usr/bin/env bash
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/role-directive.sh"

you_decide=$'YOU DECIDE: nothing of its own — this plugin has no survey obligation.\nIt is a single negotiation-theory facet, shared by phase 1 and phase 2:\nBATNA statement + ZOPA estimate, checked on top of whatever the other\npartnerships-bd methodology plugins require.'
use_when=$'PROPOSAL (phase 1) and RECORD (phase 2): whenever a partnerships-bd\nscoring section or the deal-structure-verdict field is written, this\nplugin\x27s gate is the one that checks the proposer\x27s own BATNA is\nnamed explicitly, and that a ZOPA estimate is present whenever\ncounterpart-position language is used.'
produces=$'PROPOSAL (phase 1) and RECORD (phase 2): name the proposer\x27s own\nwalk-away alternative explicitly (BATNA) — never implied. Estimate\nZOPA whenever the counterpart\x27s position is known or discussed\n(adoption doc docs/issue-1/proposals/rulebook-maturation.md part\n(a).3 and (b)).'
hand_off=$'EXECUTION JUDGMENT (phase 2): this plugin fires on both the proposal\nand the record path — it has no separate hand-off; multi-axis-scoring\nand term-sheet-structure own the record\x27s remaining derivation\nsurfaces.'

core_role_directive "$you_decide" "$use_when" "$produces" "$hand_off"
