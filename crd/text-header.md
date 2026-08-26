---
status: active
figma: https://www.figma.com/design/Qayy6zy5OxSRT4cbvFqjXR?node-id=464-551
code:
---

# TextHeader

## Purpose

The title block for a screen or surface — names where the user is and, when
needed, sets the emotional frame in a line of supporting copy.

## Use when / don't use when

- Use at the top of a screen or surface to title it (e.g. "your journal"
  with its reassurance line).
- Don't use for row-level titles inside lists — that's ListRow.
- Don't use for the bar that carries navigation actions — that's TopBar;
  TextHeader sits in content, below it.

## Anatomy

- **header** — the title text.
- **subheader** (optional) — supporting copy below the header.

Each text part binds a named text style from the file — never raw type
values.

## Variants & options

- `neutral`
- `accent-one`
- `accent-two`

## Behaviour

- Static — no states, no interaction.
- Start-aligned (reads as left in LTR). Built with start/end, never
  left/right, so it flips for RTL (Flutter: directional alignment and
  `EdgeInsetsDirectional`).
- Text wraps, never truncates; the subheader may span multiple lines.

## Content

- Header names the place or surface; subheader is one or two short warm
  sentences, not instructions.

## Accessibility

- Header is exposed as a semantic heading; screen readers land on it when
  the surface opens.
- Text scales with system font size, wrapping as needed.
- All three tones meet WCAG AA on the app surfaces at body size.

## Definition of done

- Widget test per tone × with/without subheader.
- Semantic heading verified.
- RTL flip and text-scaling cases exercised.
- All values bound to tokens per the Figma variables — nothing hardcoded.
- `code:` frontmatter set.

## Ruled out

- Centred or end alignment — start-aligned only until a design needs
  otherwise.
- Absolute left/right layout — everything start/end so RTL flips free.

## Decisions

- Named TextHeader (over TitleBlock / ScreenHeader).
- Tone colours everything — header and subheader, not just the
  header; the per-part text bindings live in Figma.
- Tone prop named `tone`.
- Text parts bind named text styles, never raw type values.

## Open questions
