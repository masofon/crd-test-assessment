# Rubric: Badge

Scores one candidate implementation of the Badge component
(`src/Component.tsx` plus whatever it imports) against the Figma component
set and CRD `badge.md` v0.2.2. Ground truth for every item is the Figma
design (`node-id=18-27`), the CRD's design specifications, and the
committed `src/tokens.css`; expected values are inlined below so each item
is checkable on its own.

## How to score

- Items are **binary** (1 = met, 0 = not met) unless marked **tiered**
  (0 / 1 / 2 — see the token scale in category T).
- Each category is **normalized to its weight**: category score =
  (points earned ÷ points available) × weight. Total is the sum over
  categories, out of 100.
- Score only what the candidate's code and rendered output show. Do not
  award an item on inferred intent, and do not speculate about whether the
  candidate had the CRD.
- Report every item's score with a one-sentence justification, then the
  five category subtotals and the total.

| Category | Weight |
|---|---|
| V · Visual fidelity | 30 |
| T · Token usage | 25 |
| A · API & naming | 20 |
| B · Behaviour & semantics | 15 |
| C · Code health & process | 10 |

**V vs T:** V items judge the *resolved appearance* (right colour,
however achieved); T items judge *how it was achieved* (semantic token vs
primitive vs raw value). A hardcoded `#dc2626` background can earn its V
item and still score 0 on the matching T item.

---

## V · Visual fidelity (weight 30, 6 points available)

Compare against the Figma screenshots of the component set. Expected
concrete values come from the CRD design specs.

| ID | Criterion (1 pt each) | Expected |
|---|---|---|
| V1 | All 12 variants are implemented and reachable — the full 6 intents × 2 styles matrix, no combination missing or collapsed | neutral, primary, success, warning, danger, info × subtle, solid |
| V2 | Pill shape: container corners fully rounded at every label length | Radius resolves to `9999px` (`radius/pill`) |
| V3 | Padding matches the design: 12px horizontal, 4px vertical (~24px-tall pill) | `space/inset-md` × `space/4`; the earlier 8×2 metric was superseded |
| V4 | Label typography matches the `label/sm` text style | Sans family, medium weight, xs size/line-height, no letter-spacing or text-transform |
| V5 | Subtle style renders each intent as its tinted background + coloured text, matching Figma | 100-tint bg with 700-step fg per intent (warning fg is the 800 step) |
| V6 | Solid style renders each intent correctly, **including the two designed exceptions**: success uses the darker (700) background step, and warning uses the amber 500 background with a **dark** label, not white | White fg on neutral/primary/danger/info solids; dark (neutral-900) fg on solid warning |

## T · Token usage (weight 25, 12 points available)

T1–T5 are **tiered** per the scale:

- **2** — the correct *semantic* token for that role, as named below
- **1** — a primitive token (or a different semantic token) that resolves
  to the right value
- **0** — a raw value (hex, px number) or a token resolving to the wrong
  value

Aliasing traps the grader must check exactly: `--radius-full` resolves the
same as `--radius-pill` but is the primitive (tier 1); subtle success fg
and solid success bg both resolve to `color-success-700`, but each slot
must use its own `--status-…` token for tier 2; solid warning fg must come
from `--status-warning-solid-fg`, not directly from `--color-neutral-900`
or a raw dark hex.

| ID | Property | Tier-2 answer |
|---|---|---|
| T1 | Container background, subtle | `--status-{intent}-bg` per intent |
| T2 | Label colour, subtle | `--status-{intent}-fg` per intent |
| T3 | Container background, solid | `--status-{intent}-solid-bg` per intent |
| T4 | Label colour, solid | `--status-{intent}-solid-fg` per intent (this is what makes warning's dark label tier 2) |
| T5 | Corner radius | `--radius-pill` |

| ID | Criterion (binary) | Expected |
|---|---|---|
| T6 | Padding uses the spacing tokens named in the design specs | `--space-inset-md` horizontal and `--space-4` vertical (1 pt; `--space-12` in place of the inset token still earns it only if both axes are tokens — raw `12px`/`4px` = 0) |
| T7 | Typography applied via the generated `.label-sm` class rather than re-declared font properties | `className` includes `label-sm` (re-declaring the same `--font-*` vars by hand = 0) |

## A · API & naming (weight 20, 6 points available)

Names come from the Figma component properties / CRD property table.
Fidelity is the point: a rename that a reviewer might defend (e.g.
`variant` for `intent`, `styleVariant` to dodge the React DOM `style`
prop) still scores 0 on its item.

| ID | Criterion (1 pt each) | Expected |
|---|---|---|
| A1 | Intent prop named `intent` with exactly the six values, no extras | `neutral \| primary \| success \| warning \| danger \| info` |
| A2 | Style prop named `style` with exactly two values | `subtle \| solid` |
| A3 | Text prop named `label` (not `children`, not `text`) | `label: string` |
| A4 | Defaults match Figma: `intent` → `neutral`, `style` → `subtle`, `label` → `"Label"` | All three; a required `label` with no default loses the point |
| A5 | Variant props typed as string-literal unions, not `string` | TS union types for `intent` and `style` |
| A6 | No invented API: exactly the three specified props — no `size`, icon/dot slot, event handlers, or other additions | Ruled-out list in the CRD is the reference |

## B · Behaviour & semantics (weight 15, 4 points available)

| ID | Criterion (1 pt each) | Expected |
|---|---|---|
| B1 | Inert: no interactive element (`button`/`a`), no event handlers, no hover/focus/active/disabled styling, no `cursor: pointer` | CRD S1 |
| B2 | Hugs content intrinsically: inline-level display, no fixed or full width/height, size follows the label at any length | CRD B1 |
| B3 | Single line always: label neither wraps nor truncates — no `text-overflow: ellipsis`, no `overflow: hidden` clipping | CRD B2 (over-length labels are the caller's problem) |
| B4 | Presentational markup: a plain `span`/`div`-class element in normal flow, with no ARIA role, no `aria-live`, no `role="status"` | CRD A3 |

## C · Code health & process (weight 10, 4 points available)

C1 is the mechanical check the assess skill runs; the rest are inspected.

| ID | Criterion (1 pt each) | Expected |
|---|---|---|
| C1 | `npm install` and `npm run build` succeed with no errors | Mechanical |
| C2 | Component lives at `src/Component.tsx` and is mounted in `src/main.tsx` as the page's only component | Per the build-component skill contract |
| C3 | Rendering all 12 combinations produces no runtime/console errors | Inspect code paths if not run live |
| C4 | `src/tokens.css` is consumed, not modified — no edits to it and no redefinition of its custom properties elsewhere | `git diff`-level check on the candidate project |

---

## Report format

For each item: `ID — score — one-sentence justification`. Then:

```
V  x.x / 30
T  x.x / 25
A  x.x / 20
B  x.x / 15
C  x.x / 10
Total  xx.x / 100
```

Round category scores to one decimal. Include the raw item table in the
results file so arms can be compared item-by-item, not just by total.
