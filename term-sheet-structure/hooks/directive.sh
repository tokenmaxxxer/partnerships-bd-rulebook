#!/usr/bin/env bash
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/role-directive.sh"

you_decide=$'YOU DECIDE: nothing of its own — this plugin has no survey obligation.\nIt is a single phase-2-record-only facet: the 7-subsection term-sheet\nstructure, checked on top of whatever the other partnerships-bd\nmethodology plugins require.'
use_when=$'RECORD (phase 2 only): whenever the partnerships-bd phase-2 record\x27s\nterm-sheet-outline field is written, this plugin\x27s gate is the one\nthat checks all 7 named sub-sections appear, in order, with exit/\ntermination present (non-optional) and governance kept distinct from\nKPIs.'
produces=$'RECORD (phase 2 only): emit all 7 named term-sheet sub-sections in\norder — purpose, roles & responsibilities, terms, governance, KPIs,\ndispute resolution, exit/termination. Exit/termination is non-optional;\ngovernance and KPIs are kept as distinct sub-sections, never merged\n(adoption doc docs/issue-1/proposals/rulebook-maturation.md part (b)).'
hand_off=$'EXECUTION JUDGMENT (phase 2): this plugin owns the term-sheet-outline\nfield only — multi-axis-scoring and batna-zopa own the record\x27s\ndeal-structure-verdict derivation.'

core_role_directive "$you_decide" "$use_when" "$produces" "$hand_off"
