# Rubric: Badge

Scores one candidate implementation of Badge (`src/components/badge.tsx` plus
what it imports). The project holds other components too; they are out of
scope, as is `src/components/badge.preview.tsx`, which is demo scaffolding.

This rubric is **self-contained**: every expected token name, property
name, value set and default is inlined below, taken from the Figma
component set (`node-id=18-27`) and CRD `badge.md` v0.2.2. Everything is
scored from this file and the candidate's own committed `src/tokens.css`.

**Scope of this rubric:** the *connections*, not the pixels. Assume code
generation reproduces the design pixel-for-pixel — that is not what is
being measured. Points go only to (a) binding each styled property to the
exact token Figma binds it to, and (b) reproducing the exact properties,
values and defaults Figma declares, plus the behaviour those imply. Nothing
is awarded for a colour or metric that merely *looks* right.

## How to score

- **Tiered** items score 0 / 1 / 2 on the token scale in category T.
- **Binary** items score 0 or 1.
- Category score = (earned ÷ available) × weight. Total is out of 100.
- Score only what the code shows. No credit for inferred intent.
- Report every item as `ID — score — one-sentence justification`.

| Category | Weight | Points available |
|---|---|---|
| T · Token bindings | 50 | 16 (8 tiered) |
| P · Figma properties | 30 | 6 |
| B · Behaviour & semantics | 20 | 4 |

---

## T · Token bindings (weight 50, 16 points available)

Every item is **tiered**:

- **2** — the exact token Figma binds to that property, by name.
- **1** — a different token that resolves to the same value (a primitive
  behind the semantic, or an unrelated semantic that happens to match).
- **0** — a raw value (hex, px, `9999px`), or any token resolving to the
  wrong value.

Tier-1 traps the grader must check by name, not by resolved value:

- `--radius-full` is the primitive behind `--radius-pill` → tier 1.
- `--space-12` is the primitive behind `--space-inset-md` → tier 1.
- `--space-inset-xs` and `--space-gap-xs` both resolve to `4px` but are
  not what Figma binds for vertical padding → tier 1.
- Subtle success fg and solid success bg both resolve to
  `--color-success-700`; each slot must name its own `--status-…` token.
- Solid warning fg must come from `--status-warning-solid-fg`, not from
  `--color-neutral-900` or a dark hex.
- Solid fg on the other five intents must come from
  `--status-{intent}-solid-fg`, not `--color-base-white` or `#fff`.

An item covering all six intents scores at its **weakest** intent: one
intent hardcoded or mis-mapped caps that item at the tier that intent earns.

| ID | Property (Figma layer → CSS) | Tier-2 token |
|---|---|---|
| T1 | `container` fill, style = subtle | `--status-{intent}-bg` ×6 |
| T2 | `label` fill, style = subtle | `--status-{intent}-fg` ×6 |
| T3 | `container` fill, style = solid | `--status-{intent}-solid-bg` ×6 |
| T4 | `label` fill, style = solid | `--status-{intent}-solid-fg` ×6 |
| T5 | `container` corner radius | `--radius-pill` |
| T6 | `container` horizontal padding | `--space-inset-md` |
| T7 | `container` vertical padding | `--space-4` |
| T8 | `label` typography | the generated `.label-sm` class, applied as a class — re-declaring `--font-family-sans` / `--font-weight-medium` / `--font-size-xs` / `--font-line-height-xs` by hand is tier 1; raw `12px`/`500` is tier 0 |

## P · Figma properties (weight 30, 6 points available)

Names, value sets and defaults come from the Figma component properties.
Fidelity is the point: a defensible rename (`variant` for `intent`,
`styleVariant` to dodge React's `style` prop, `children` for `label`)
scores 0.

| ID | Criterion (1 pt) | Expected |
|---|---|---|
| P1 | Variant property `intent`, exactly six values, no extras | `neutral \| primary \| success \| warning \| danger \| info` |
| P2 | Variant property `style`, exactly two values | `subtle \| solid` |
| P3 | Text property `label` | `label: string` |
| P4 | Defaults match Figma's default variant and text | `intent="neutral"`, `style="subtle"`, `label="Label"`; a required `label` with no default loses the point |
| P5 | Both variant props are string-literal unions, not `string` | TS unions for `intent` and `style` |
| P6 | No property Figma does not declare — no `size`, icon/dot slot, `className` escape hatch, event handlers | CRD "Ruled out" is the reference |

## B · Behaviour & semantics (weight 20, 4 points available)

| ID | Criterion (1 pt) | Expected |
|---|---|---|
| B1 | Inert: no `button`/`a`, no event handlers, no hover/focus/active/disabled styling, no `cursor: pointer` | CRD S1 |
| B2 | Hugs content: inline-level, no fixed or full width/height, size follows the label at any length | CRD B1 |
| B3 | Single line always — no wrapping, no `text-overflow: ellipsis`, no `overflow: hidden` clipping | CRD B2 |
| B4 | Presentational: plain `span` in normal flow, no `role`, no `aria-live`, no `role="status"` | CRD A3 |

---

## Disqualifying check (not scored — reported)

`src/tokens.css` must be consumed unmodified: no edits to it, and no
redefinition of its custom properties elsewhere. If it was modified, report
it prominently — every T score is read against a moved goalpost.

---

## Report format

```
T  x.x / 50
P  x.x / 30
B  x.x / 20
Total  xx.x / 100
```

Round to one decimal. Include the raw item table so arms compare
item-by-item, not just by total.
