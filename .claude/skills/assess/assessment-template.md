# Assessment: {Component} — {candidate}

## Mechanical

- `npm install`: {succeeded | failed} ({one-line detail — e.g. "up to date, 0 vulnerabilities" or the error}).
- `npm run build` (`{build command}`): {succeeded | failed} ({one-line detail — e.g. "no errors" or the first error}).

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
| {V2} | {0/1} | {One sentence naming what is missing or wrong, and what was found instead.} |
| {T3} | {1/2} | {One sentence naming what was found and why it falls short of the top tier.} |
| … | … | … |

### Full marks

| ID | Score | Justification |
|---|---|---|
| {V1} | {1/1} | {One sentence naming the concrete evidence — selector, prop, resolved value, or file.} |
| {T1} | {2/2} | {One sentence naming the token actually used and its tier.} |
| … | … | … |

## Category subtotals

Category score = (points earned ÷ points available) × weight, rounded to
one decimal. Total is the sum over categories, out of 100.

```
V  {x.x} / {30}
T  {x.x} / {25}
A  {x.x} / {20}
B  {x.x} / {15}
C  {x.x} / {10}
Total  {xx.x} / 100
```
