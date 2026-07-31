# Scout brief — partnerships-bd domain norms (issue-1)

Subject: issue-1 phase 1. Live web search was available and used (see
Sources); this brief blends those results with well-established
textbook/industry knowledge, labeled inline where a claim is not tied to
a specific search result.

## (a) Partnership proposal norms — must-bes

- **Strategic-fit gate before anything else.** Strong BD practice
  assesses strategic/ICP fit *before* financial or legal diligence — a
  financially clean but strategically misaligned partner is still the
  wrong partner (established practice, confirmed by search).
- **ICP/audience overlap as a named, checkable criterion**, not a vibe:
  the partner's customer base must overlap the proposer's ICP, ideally
  with a named validation method (e.g. account-overlap tooling),
  otherwise the proposal is "building on an assumption, not a
  foundation."
- **Weighted, multi-axis due-diligence scoring**: representative
  practice covers ~8 assessment areas (strategic fit, ICP/audience fit,
  financial health, legal/compliance posture, operational capability,
  cultural fit, compounding-value test, risk class) with explicit
  relative weights, not a flat checklist.
- **Deal-structuring logic named explicitly**: BATNA (Best Alternative
  to a Negotiated Agreement) as the evaluative anchor, and ZOPA (Zone of
  Possible Agreement) as the target range — textbook Harvard PON/BATNA
  literature, confirmed by search. A credible proposal states the
  proposer's own BATNA/walk-away position, not just the ask.
- **MOU/LOI convention** (established domain knowledge, not directly
  confirmed by search results returned): a phase-1 proposal that intends
  to become a real deal should distinguish non-binding intent (LOI/MOU)
  from binding terms, and say which stage this proposal represents.
- **Citation/evidence format**: credible BD proposals cite either (i)
  named frameworks/sources for methodology claims, or (ii) primary
  evidence (data-sharing tool output, financial statements, reference
  calls) for factual claims about a specific partner — not bare
  assertion.

## (b) Phase-2 deliverable/output norms — must-bes

- **Full agreement skeleton**, not just a verdict: purpose/name of
  partnership, roles & responsibilities, profit/value-sharing or
  capital-contribution terms, decision-making authority thresholds
  (governance), dispute resolution mechanism, KPIs/success metrics tied
  to accountability, and an exit/termination clause with notice periods
  and wind-down obligations.
- **Governance is a distinct section from KPIs**: clear roles + KPIs are
  named separately in the literature as the two things "critical for
  success" — a deliverable that only states metrics without a
  decision-rights model is thin.
- **Exit clause is non-optional**: absence of an exit clause is called
  out by name as a recurring failure mode leading to disputes.

## One pattern to adopt / one to skip

- **Adopt**: weighted multi-axis scoring for the evaluation step (a) —
  it forces the proposal to show its arithmetic rather than assert a
  verdict, and maps directly onto this role's existing
  `REQUIRED_FIELDS` (`deal-structure-verdict`, `term-sheet-outline`) as
  the thing the verdict must be derived *from*.
- **Skip**: importing full JV/technology-integration-specific diligence
  checklists wholesale (e.g. the full 8-area CheckFlow-style template) —
  over-fit to a specific deal type (JV/tech integration/white-label) this
  role has not committed to; adopt the *shape* (weighted multi-axis) not
  the fixed area list.

## Gap line — current rulebook state vs scout findings

Current state (post issue-2 core-canon conversion): `directive.sh`
declares `PRODUCES = deal structure verdict, term sheet outline` and
`record-fields.config` enforces those two fields exist in the record.
Neither the directive nor any doc in this repo specifies *how* the
verdict must be derived (no strategic-fit/ICP-fit method named, no
BATNA/ZOPA framing, no weighting) or *what* the term sheet outline must
contain (no governance/KPI/exit-clause component list). The role has a
required-fields gate but no required-*methodology* or
required-*content* behind those fields — this is exactly the gap issue-1
asks phase 1 to close.

## Sources

- [How to Assess Partnership Fit: Key Criteria and Evaluation Methods](https://techannouncer.com/how-to-assess-partnership-fit-key-criteria-and-evaluation-methods/)
- [Business Partnership Due Diligence Checklist Template](https://checkflow.io/templates/due-diligence/business-partnership-due-diligence-checklist)
- [Partnership Evaluation Checklist Guide](https://influenceflow.io/resources/partnership-evaluation-checklist-complete-guide-to-assessing-business-partnerships-in-2026/)
- [Strategic Partnership Agreement: Key Elements and Benefits](https://www.sirion.ai/library/contracts/strategic-partnership-agreement/)
- [Partnership governance — FasterCapital](https://fastercapital.com/content/Partnership-governance--Establishing-Governance-in-Your-Partnership-Agreement.html)
- [Partnership Agreement Guide With Types, Clauses & Examples](https://trackier.com/partnership-agreement-guide-with-types-examples/)
- [What is BATNA? — PON, Harvard Law School](https://www.pon.harvard.edu/tag/batna/)
- [Best alternative to a negotiated agreement — Wikipedia](https://en.wikipedia.org/wiki/Best_alternative_to_a_negotiated_agreement)
