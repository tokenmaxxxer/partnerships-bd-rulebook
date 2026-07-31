#!/usr/bin/env bash
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/role-directive.sh"

you_decide=$'YOU DECIDE: nothing of its own — this plugin has no survey obligation.\nIt is a single scoring facet, shared by phase 1 and phase 2: the\nweighted multi-axis evaluation table (see reference/axes.md for the\ncanonical 6-axis list), checked on top of whatever the other\npartnerships-bd methodology plugins require.'
use_when=$'PROPOSAL (phase 1) and RECORD (phase 2): whenever a partnerships-bd\nscoring table or the deal-structure-verdict field is written, this\nplugin\x27s gate is the one that checks all six named axes appear, each\nwith an explicit weight and score.'
produces=$'PROPOSAL (phase 1): a weighted multi-axis evaluation table naming all six\naxes from reference/axes.md, each with an explicit weight and score.\nRECORD (phase 2): the deal-structure-verdict field must show the same\nsix-axis derivation, not just a final yes/no/score (adoption doc\ndocs/issue-1/proposals/rulebook-maturation.md part (a).2 and (b)).'
hand_off=$'EXECUTION JUDGMENT (phase 2): this plugin fires on both the proposal and\nthe record path — it has no separate hand-off; batna-zopa and\nterm-sheet-structure own the record\x27s remaining derivation surfaces.'

core_role_directive "$you_decide" "$use_when" "$produces" "$hand_off"
