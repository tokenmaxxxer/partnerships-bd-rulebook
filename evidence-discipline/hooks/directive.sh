#!/usr/bin/env bash
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/role-directive.sh"

you_decide=$'YOU DECIDE: nothing of its own — this plugin has no survey or record\nobligation. It is a single phase-1 proposal-write facet: stage\ndeclaration and citation discipline, checked on top of whatever the\nother partnerships-bd methodology plugins require.'
use_when=$'PROPOSAL (phase 1): whenever a partnerships-bd phase-1 proposal is\nwritten, this plugin\x27s gate is the one that checks a stage declaration\n(non-binding vs binding-terms-ready) is present, and that at least one\nsource/citation is stated for framework or factual claims.'
produces=$'PROPOSAL (phase 1): declare the proposal\x27s stage explicitly — either\nnon-binding or binding-terms-ready — and cite a source per framework\nclaim and per factual candidate-partner claim (adoption doc\ndocs/issue-1/proposals/rulebook-maturation.md parts (a).4 and (a).5).'
hand_off=$'EXECUTION JUDGMENT (phase 2): this plugin has no phase-2 obligation and\nstays silent on the record path — the phase-2 record does not re-declare\nstage or re-cite framework claims.'

core_role_directive "$you_decide" "$use_when" "$produces" "$hand_off"
