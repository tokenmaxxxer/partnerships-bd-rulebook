#!/usr/bin/env bash
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/role-directive.sh"
YOU_DECIDE="YOU DECIDE: 파트너십이 구조적으로 성립하는가"
USE_WHEN="USE_WHEN: 제휴/BD 딜 구조가 걸릴 때"
PRODUCES=$'PRODUCES (required record fields): deal structure verdict, term sheet outline (see reference/deliverable-shapes.md for required shape)\nWRITE_SCOPE: []'
HAND_OFF=$'HAND-OFF: 법적 계약 검토는 → legal-compliance\n\nBOUNDARY CASE: if the work in front of you drifts outside `decides` above, stop and hand off per the arrow — do not silently absorb another role\'s scope. Record the hand-off point in this role\'s record before opening the next role\'s session.'
core_role_directive "$YOU_DECIDE" "$USE_WHEN" "$PRODUCES" "$HAND_OFF"
