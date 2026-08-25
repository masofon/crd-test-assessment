# Assessment: {Component} — {candidate}

## Mechanical (reported, not scored)

- `npm install`: {succeeded | failed} ({one-line detail — e.g. "up to date, 0 vulnerabilities" or the error}).
- `npm run build` (`{build command}`): {succeeded | failed} ({one-line detail — e.g. "no errors" or the first error}){, failing in {this component or its imports | elsewhere in the project — {where}} if it failed}.
- `src/tokens.css` consumed unmodified: {yes | NO — {what was changed or redefined, and where}}.

## Item scores

One row per rubric item, every item present — no item omitted, none
invented. Split across the two tables below: every item that lost points
goes in `Points lost`, every item that earned full marks goes in
`Full marks`. Within each table keep rubric order. `Score` is
`earned/available` (binary items are `1/1` or `0/1`; tiered items are
`2/2`, `1/2`, or `0/2`). Justification is exactly one sentence citing what
the code shows, not inferred intent. If a table would be empty, keep its
heading and write `None.` in place of the table.

### Points lost

| ID | Score | Justification |
|---|---|---|
| {P2} | {0/1} | {One sentence naming what is missing or wrong, and what was found instead.} |
| {T3} | {1/2} | {One sentence naming what was found and why it falls short of the top tier.} |
| … | … | … |

### Full marks

| ID | Score | Justification |
|---|---|---|
| {B1} | {1/1} | {One sentence naming the concrete evidence — selector, prop, resolved value, or file.} |
| {T1} | {2/2} | {One sentence naming the token actually used and its tier.} |
| … | … | … |

## Category subtotals

One line per category **the rubric defines** — its letters, its weights,
in its order; none added, none dropped. Category score = (points earned ÷
points available) × weight, rounded to one decimal. Total is the sum over
categories, out of 100.

```
{T}  {x.x} / {50}
{P}  {x.x} / {30}
{B}  {x.x} / {20}
Total  {xx.x} / 100
```
