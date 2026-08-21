<!-- CRD-META
id: badge
name: Badge
version: 0.2.2
status:
  requirements: in_progress      # not_started | in_progress | ready_for_dev
  design_specs: complete
  implementation: not_started
design: https://www.figma.com/design/Qayy6zy5OxSRT4cbvFqjXR?node-id=18-27   # component set "Badge"
code: none                       # none | [path/link once built]
related_crds: []
last_updated: 2026-08-17
-->

# CRD: Badge

<!--
See design-system/variable-architecture.md for the token system every statement
below binds to. This is the first CRD in the library: its conventions
(sentence-case labels, intent/style axis naming, status/* token usage) set
precedent for later components.
-->

---

# 1 · Requirements

*Written: pre-design. Consumed by: designer, developer, build agent, test generation, build-time audit.*

## Purpose

Badge is a small, presentational label that colours a single piece of status or
category metadata (e.g. "In progress", "Beta") so it can be scanned at a glance.
Meaning is carried by its text; colour is reinforcement, never the sole signal.

## Scope

**In scope:**

* A static, non-interactive label conveying one status or category value.

**Out of scope:**

* Interactive or removable tags — clicking, dismissing (use Chip instead)
* Notification counts or status dots attached to another element (use a Notification badge / Indicator instead)
* Standalone icon-only status indicators (use an Icon / Indicator instead)

## Anatomy

* **container** — the pill wrapper carrying background, border radius and padding
* **label** — the single line of text naming the status or category

## Functional requirements

* F1: `intent` has exactly six values — neutral, primary, success, warning, danger, info — and no others.
* F2: `style` has exactly two values — subtle, solid — and no others.
* F3: Every `intent` is available in every `style` (the full 6×2 matrix; no combination is excluded).

## States

* S1: Badge has no interactive states (no hover, focus, active) and no application states (no disabled, loading, error); it is inert in all contexts.

## Behaviour

* B1: `label` renders on a single line, and `container` hugs `label` — width and height fit the content intrinsically.
* B2: Badge neither truncates nor wraps `label`; over-length labels are a content-rule violation (see C2), not a component behaviour.
* B3: Badge has no responsive behaviour and no motion; its size is intrinsic at every viewport.

## Content

* C1: [review] `label` uses sentence case ("In progress") — not Title Case, not uppercase.
* C2: [review] `label` is short — one word where possible, two maximum (≈20 characters); it names a status or category, not an action, and carries no trailing punctuation.
* C3: [review] `label` is self-describing enough to be understood when read inline, out of its surrounding context.

## Accessibility

* A1: [review] Badge's meaning is carried by `label` text; the `intent` colour is reinforcement only and is never the sole signal.
* A2: [review] `label` maintains ≥ 4.5:1 contrast against `container` in every intent and style; consequently solid `warning` uses a dark `label` rather than white.
* A3: Badge is presentational — it renders in normal document reading order with no ARIA role and is not a live region. Announcing a status *change* is the responsibility of the parent that owns the status, not Badge.

## Integration

* I1: `container` composes no child components; Badge is a leaf.
* I2: Badge enforces nothing on any parent or sibling; the parent positions it.

**Children:**

None — Badge is text-only.

**Used in:**

Card, table/list rows, beside headings and titles, Select option rows, etc. (CRD links added as those components are written.)

## Ruled out

* A third visual style (outline): no evidenced need yet — revisit if a low-emphasis bordered treatment is required.
* A second size: no evidenced need yet — one size until both dense and roomy contexts demand distinct badges.
* Leading-icon and status-dot slots: deferred to keep v1 text-only and avoid depending on an Icon component that does not yet exist (see the icon/dot exit in Design decisions).
* Rounded-rectangle shape: pill chosen instead (see Design decisions).
* White `label` on solid `warning`: fails WCAG ≥ 4.5:1 on amber — solid warning uses a dark `label` per A2. Do not "normalise" it to white for consistency with the other solids.

## Open questions

| Question | Owner | By | Status |
|---|---|---|---|
| Add the Semantic tokens Badge's design needs: a `status/primary` subtle pair (bg + fg), and a `solid-bg` + `solid-fg` pair per intent (6), including a dark `solid-fg` for warning per A2. | Cassie / Claude | Before Badge design (design_specs) starts | ✅ Resolved 2026-08-17 (14 tokens added — see Design decisions) |

## Notes

Badge is the first CRD in the library; treat its choices as case law — sentence-case
labels (C1), the `intent` / `style` axis vocabulary (F1–F2), and binding colour to
`status/*` semantic tokens rather than primitives.

---

# 2 · Design specifications

*Written: post-design. Consumed by: developer & build agent alongside the design source.*

**Design:** [Figma — Badge component set](https://www.figma.com/design/Qayy6zy5OxSRT4cbvFqjXR?node-id=18-27) · [documentation artboard](https://www.figma.com/design/Qayy6zy5OxSRT4cbvFqjXR?node-id=19-2)

## Properties

| Property | Type | Default | Options | Description |
|---|---|---|---|---|
| `intent` | Variant | `neutral` | neutral, primary, success, warning, danger, info | Colour role (F1). Binds `container` fill and `label` fill to `status/{intent}/*` semantic tokens. Colour is reinforcement only, never the sole signal (A1). |
| `style` | Variant | `subtle` | subtle, solid | Emphasis (F2). `subtle` = tinted `bg` + coloured `fg`; `solid` = strong `solid-bg` + `solid-fg`. Every intent exists in both (F3). |
| `label` | Text | `Label` | — | The status/category text (C1–C2): sentence case, one–two words, no trailing punctuation. Drives `label.characters`. |

## Design decisions

*Entries below dated 2026-08-17 are pre-design decisions made during requirements, seeded per the crd-writing workflow.*

* 2026-08-17: Scope set to 6 intents × 2 styles (subtle, solid) × 1 size. Reverses the initial "subtle-only, 5-intent" baseline proposal after the designer chose broader variant coverage; outline style and a second size are ruled out. Why: exercise the intent/token axis harder while keeping Badge presentational.
* 2026-08-17: Pill shape (`radius/pill`) chosen over rounded-rectangle — reads as a discrete tag.
* 2026-08-17: Sentence case chosen for `label` over Title Case / uppercase — sets the library-wide label-casing precedent (C1).
* 2026-08-17: v1 is text-only; leading-icon and status-dot slots deferred to avoid a dependency on a not-yet-existing Icon component.
* 2026-08-17 (design): Closed the token Open question — added 14 Semantic tokens: `status/primary/{bg,fg}` (subtle) and `status/{intent}/{solid-bg,solid-fg}` ×6. Why: subtle needed the new brand intent; solid needed its own bg/fg set.
* 2026-08-17 (design): Solid `solid-bg` steps chosen by WCAG contrast against their `solid-fg` (A2): `600` for neutral/primary/danger/info, `700` for success (600 gave only ~3.3:1 on white), and `warning` = amber `500` paired with a **dark `neutral/900`** label (white fails). This is the concrete realisation of A2's "solid warning uses dark text".
* 2026-08-17 (design): Metrics — horizontal padding `space/inset-sm` (8), vertical `space/2` (2) → ~20px pill; `label` uses the `label/sm` text style. Small executional choices within the pill/hug constraints; no size axis introduced.
* 2026-08-17 (design): Padding increased to `space/inset-md` (12) horizontal, `space/4` (4) vertical (~24px pill) per designer feedback — reverses the tighter inset-sm/space/2 metric above. Roomier feel; still one size.
* 2026-08-17 (post-review): Added a Ruled out line guarding the white-on-solid-warning rejection (already stated in A2) so agents don't "normalise" it. No design change — a Phase-5 step-4 omission caught on review.

---

# 3 · Implementation

*Written: pre-dev & during dev, by the developer. Consumed by: the build agent as direct instructions, future maintainers, & the designer via flagged deviations.*

## Implementation decisions

* YYYY-MM-DD:

## Dev notes & deviations

* YYYY-MM-DD:
