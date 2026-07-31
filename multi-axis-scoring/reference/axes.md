# Canonical scoring axes — multi-axis-scoring

Single source of truth for the six named axes required by both the
phase-1 proposal's evaluation table and the phase-2 record's
`deal-structure-verdict` derivation. Fixed by
`docs/issue-1/proposals/rulebook-maturation.md` part (a).2.

1. strategic/ICP fit
2. financial health
3. legal/compliance posture
4. operational capability
5. cultural fit
6. compounding-value

Each axis carries an explicit weight and score; the scores sum to the
verdict. `hooks/multi-axis-scoring-gate.sh` and `hooks/directive.sh`
both read this list rather than duplicating it.
