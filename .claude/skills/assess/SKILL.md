---
name: assess
description:
  Score one anonymized component file against the component's rubric,
  writing a report to the given results file.
arguments: [component, component-file, results-file]
argument-hint: <component> <component-file> <results-file>
allowed-tools: [Read, Glob, Grep, Write, Edit, Bash]
---

Score the component implementation at `$component-file` against
`rubric/$component.md`. Do not speculate about the implementation's
origin — score only what is in its project.

The project holds several components. Score `$component-file` and the
files it imports, and nothing else: not the other components in
`src/components/`, not `src/main.tsx`, and not `$component-file`'s own
`*.preview.tsx`, which is demo scaffolding rather than the component.

## Ground truth

`rubric/$component.md` is self-contained: it inlines every expected token
name, property name, value set and default. Read it, then read the
candidate's own `src/tokens.css` to resolve what each token the candidate
used actually evaluates to. `crd/$component.md`, *if present*, is
background only; where it and the rubric disagree, the rubric wins. A
component need not have one.

## Scoring

1. Run `npm install` then `npm run build` in the project containing
   `$component-file` (the nearest ancestor directory with a
   `package.json`). This is **reported, not scored** — the rubric awards
   no points for it — but a failed build is context for every item below.
   One bad component fails the build for the whole project, so say
   whether the failure is in `$component-file` or its imports, or
   somewhere else in the project.
2. Check the rubric's disqualifying check: whether `src/tokens.css` was
   modified or its custom properties redefined elsewhere. Report it; do
   not score it. This is a property of the whole project rather than of
   one component — report what you find without attributing it to
   `$component-file`; the run log records which build touched it.
3. Score the judged criteria per the rubric, comparing the component code
   to the expected values inlined there.
4. Write `$results-file`, creating its parent directory: mechanical
   outcomes, the disqualifying check, and each judged score with its
   justification. Keep each justification to a single sentence. Follow
   `assessment-template.md` in this skill directory — same sections, same
   order, same score format — replacing every `{placeholder}` and dropping
   the template's instructional prose.
