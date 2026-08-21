---
name: assess
description:
  Score one anonymized component file against the component's rubric,
  writing a report to the given results file.
arguments: [component, component-file, figma-url, results-file]
argument-hint: <component> <component-file> <figma-url> <results-file>
---

Score the component implementation at `$component-file` against
`rubric/$component.md`. Do not speculate about the implementation's
origin — score only what is in its project.

## Ground truth

Read `rubric/$component.md` and `crd/$component.md`, then the Figma
component at the `$figma-url` (`get_design_context`, `get_variable_defs`,
and `get_screenshot`) before scoring anything.

## Scoring

1. Mechanical checks: run `npm install` then `npm run build` in the
   project containing `$component-file` (the nearest ancestor directory
   with a `package.json`).
2. Score the judged criteria per the rubric, comparing the component code
   to the Figma reads and the requirements.
3. Write `$results-file`, creating its parent directory: mechanical
   outcomes, each judged score with its justification. Keep each score
   justification to a single sentence. Follow `assessment-template.md`
   in this skill directory — same sections, same order, same score
   format — replacing every `{placeholder}` and dropping the template's
   instructional prose.
