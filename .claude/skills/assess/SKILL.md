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

## Ground truth

`rubric/$component.md` is self-contained: it inlines every expected token
name, property name, value set and default. Read it, then read the
candidate's own `src/tokens.css` to resolve what each token the candidate
used actually evaluates to. `crd/$component.md` is background only; where
it and the rubric disagree, the rubric wins.

## Scoring

1. Run `npm install` then `npm run build` in the project containing
   `$component-file` (the nearest ancestor directory with a
   `package.json`). This is **reported, not scored** — the rubric awards
   no points for it — but a failed build is context for every item below.
2. Check the rubric's disqualifying check: whether `src/tokens.css` was
   modified or its custom properties redefined elsewhere. Report it; do
   not score it.
3. Score the judged criteria per the rubric, comparing the component code
   to the expected values inlined there.
4. Write `$results-file`, creating its parent directory: mechanical
   outcomes, the disqualifying check, and each judged score with its
   justification. Keep each justification to a single sentence. Follow
   `assessment-template.md` in this skill directory — same sections, same
   order, same score format — replacing every `{placeholder}` and dropping
   the template's instructional prose.
