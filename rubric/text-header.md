# Rubric: TextHeader

Scores one candidate implementation of TextHeader
(`src/components/text-header.tsx` plus what it imports). The project holds
other components too; they are out of scope, as is
`src/components/text-header.preview.tsx`, which is demo scaffolding.

This rubric is **self-contained**: every expected token name, property
name, value set and default is inlined below, taken from the Figma
component set (`node-id=464-551`) and CRD `text-header.md`. Everything is
scored from this file and the candidate's own committed `src/tokens.css`.

**Scope of this rubric:** the *connections*, not the pixels. Assume code
generation reproduces the design pixel-for-pixel — that is not what is
being measured. Points go only to (a) binding each styled property to the
exact token Figma binds it to, and (b) reproducing the exact properties,
values and defaults Figma declares, plus the behaviour those imply.
Nothing is awarded for a colour or metric that merely *looks* right.

## How to score

- **Tiered** items score 0 / 1 / 2 on the token scale in category T.
- **Binary** items score 0 or 1.
- Category score = (earned ÷ available) × weight. Total is out of 100.
- Score only what the code shows. No credit for inferred intent.
- Report every item as `ID — score — one-sentence justification`.

| Category | Weight | Points available |
|---|---|---|
| T · Token bindings | 50 | 10 (5 tiered) |
| P · Figma properties | 30 | 7 |
| B · Behaviour & semantics | 20 | 6 |

---

## T · Token bindings (weight 50, 10 points available)

Every item is **tiered**:

- **2** — the exact token Figma binds to that property, by name; for
  typography, the generated text-style class applied as a class.
- **1** — a different token that resolves to the same value (a primitive
  behind the semantic, or an unrelated semantic that happens to match), or
  a text style's fields re-declared by hand from the right tokens.
- **0** — a raw value (hex, `8px`, `20px`, `600`), or any token resolving
  to the wrong value.

Tier-1 traps the grader must check by name, not by resolved value:

- `--color-neutral-900` / `--color-neutral-600` / `--color-neutral-400`
  are the primitives behind `--text-primary` / `--text-secondary` /
  `--text-muted` → tier 1.
- **`--text-muted` and `--text-disabled` both resolve to `#94a3b8`**
  (`--color-neutral-400`), and the `accent-two` row is the only place they
  are told apart: its `header` is `--text-muted` and its `subheader` is
  `--text-disabled`. The two are visually identical, so this must be graded
  by token name — a candidate that reuses `--text-muted` for `accent-two`'s
  subheader renders pixel-for-pixel correctly and is tier 1.
- `--space-8` is the primitive behind `--space-gap-sm` → tier 1;
  `--space-inset-sm` also resolves to `8px` but is an inset token, not the
  gap Figma binds → tier 1.
- `heading/md` and `heading/sm` share `--font-line-height-lg` and
  `--font-weight-semibold` and differ only in size — a candidate that gives
  both parts the same class has the wrong style on one of them, not a
  near-miss.

An item covering all three tones scores at its **weakest** tone: one tone
hardcoded or mis-mapped caps that item at the tier that tone earns.

| ID | Property (Figma layer → CSS) | Tier-2 token |
|---|---|---|
| T1 | `header` fill, per tone ×3 | `--text-primary` (neutral), `--text-secondary` (accent-one), `--text-muted` (accent-two) |
| T2 | `subheader` fill, per tone ×3 | `--text-secondary` (neutral), `--text-muted` (accent-one), `--text-disabled` (accent-two) |
| T3 | `header` typography | the generated `.heading-md` class, applied as a class — re-declaring `--font-family-sans` / `--font-weight-semibold` / `--font-size-xl` / `--font-line-height-lg` by hand is tier 1; raw `20px`/`600` is tier 0 |
| T4 | `subheader` typography | the generated `.heading-sm` class, applied as a class — same tiering as T3, with `--font-size-lg` |
| T5 | vertical gap between `header` and `subheader` | `--space-gap-sm` |

Figma binds **each part its own fill** — the two are one step apart on the
text-role ramp in every tone, so `header` and `subheader` are separate
slots and a candidate that sets one colour on the wrapper and lets both
parts inherit it gets T1 on its merits and **0** on T2.

| tone | `header` (T1) | `subheader` (T2) |
|---|---|---|
| `neutral` | `--text-primary` | `--text-secondary` |
| `accent-one` | `--text-secondary` | `--text-muted` |
| `accent-two` | `--text-muted` | `--text-disabled` |

## P · Figma properties (weight 30, 7 points available)

Names, value sets and defaults come from the Figma component properties.
Fidelity is the point: a defensible rename (`variant` for `tone`,
`title`/`subtitle` for `header`/`subheader`, `children` for the header
text) scores 0 — the CRD's Decisions fix the prop name as `tone` and the
part names as header/subheader.

| ID | Criterion (1 pt) | Expected |
|---|---|---|
| P1 | Variant property `tone`, exactly three values, no extras | `neutral \| accent-one \| accent-two` |
| P2 | Text property `header` | `header: string` |
| P3 | Boolean property `showSubheader` | `showSubheader: boolean` — a component that instead infers the subheader's presence from `subheader` being undefined loses the point, however reasonable that is |
| P4 | Text property `subheader` | `subheader: string`, separate from P3's boolean |
| P5 | Defaults match Figma's default variant and text | `tone="neutral"`, `header="Page title"`, `showSubheader={true}`, `subheader="This is a subtitle that can run over a couple of lines"`; any of these required with no default loses the point |
| P6 | `tone` is a string-literal union, not `string` | TS union for `tone` |
| P7 | No property Figma does not declare — no `align`, no `size`, no heading-level prop, no `className` escape hatch, no event handlers | CRD "Ruled out" is the reference |

## B · Behaviour & semantics (weight 20, 6 points available)

| ID | Criterion (1 pt) | Expected |
|---|---|---|
| B1 | Inert: no `button`/`a`, no event handlers, no hover/focus/active styling, no `cursor: pointer` | CRD Behaviour — static, no states, no interaction |
| B2 | `header` is a semantic heading element (`h1`–`h6`), not a styled `div`/`span`/`p` | CRD Accessibility — "exposed as a semantic heading" |
| B3 | `showSubheader={false}` renders no subheader element at all — conditionally omitted, not an empty `<p>` and not `visibility: hidden`; the gap goes with it | Figma renders the subheader under `showSubheader &&` |
| B4 | Wraps, never truncates: no `text-overflow: ellipsis`, no `-webkit-line-clamp`, no `white-space: nowrap`, no `overflow: hidden` clipping; the subheader may run to multiple lines | CRD Behaviour |
| B5 | Direction-agnostic: alignment and spacing use logical properties (`text-align: start`, `align-items: flex-start` in a block/flex column, `padding-inline-*`, `margin-inline-*`) — any `left`/`right` physical property loses the point | CRD Behaviour — "built with start/end, never left/right" |
| B6 | Scales with user font size and fills its parent: no fixed `px` font size on either part, no fixed `height` that would clip grown text, and no hard-coded `width: 302px` (Figma's frame width is the artboard, not a constraint) | CRD Accessibility — "text scales with system font size, wrapping as needed" |

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
