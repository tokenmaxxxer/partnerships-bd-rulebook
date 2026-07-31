#!/usr/bin/env bash
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/role-directive.sh"

you_decide=$'YOU DECIDE: nothing of its own — this plugin has no survey or record\nobligation. It is a single phase-1 proposal-write facet: strategic/ICP-fit\nand compounding-value framing, checked before any scoring table, on top\nof whatever the other partnerships-bd methodology plugins require.'
use_when=$'PROPOSAL (phase 1): before a partnerships-bd phase-1 proposal opens its\nfirst scoring table, this plugin\x27s gate is the one that checks the\nstrategic-fit/ICP-overlap and compounding-value opening statement is\npresent and comes first — it does not own the scoring table itself\n(multi-axis-scoring does) or any phase-2 record field.'
produces=$'PROPOSAL (phase 1): open every proposal with an explicit strategic-fit /\nICP-overlap statement and an explicit compounding-value statement,\nbefore any weighted scoring table appears. A wrong-partner deal must not\nclear the door on financial/legal criteria alone (adoption doc\ndocs/issue-1/proposals/rulebook-maturation.md part (a).1).'
hand_off=$'EXECUTION JUDGMENT (phase 2): this plugin has no phase-2 obligation and\nstays silent on the record path — strategic-fit rigor is proposal-stage\nonly, already satisfied upstream by the time phase 2 opens.'

core_role_directive "$you_decide" "$use_when" "$produces" "$hand_off"
