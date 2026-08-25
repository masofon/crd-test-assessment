# crd-test-assessment

Assessment side of the CRD effectiveness test: does giving a builder agent a
Component Requirements Doc (CRD) alongside the Figma component produce a
better React component than the Figma component alone?

A trial builds several components, one after another, into the same clone —
so what it measures is whether a CRD helps across a growing component set,
not whether it helps on one component in isolation.

This repo holds the component list (`component-list.tsv`), per-component
rubrics (`rubric/`), the scoring skill (`.claude/skills/assess/`), and
per-component CRDs (`crd/`). The builder must never see this repo; a CRD
crosses over only by an explicit file copy. See
[Keeping the builds honest](docs/keeping-the-builds-honest.md) for how that is
enforced.

## Running a trial

`./run-test.sh` runs a whole trial end to end — every build, every assessment,
and prints which candidate had the CRDs. It always builds the components in
`component-list.tsv`; there is nothing to pass it.

```
./run-test.sh
./run-test.sh -n   # print the plan, build nothing
```

## The component list

`component-list.tsv` is the component list, the build order and the Figma
URLs — one component per line, `<name> <TAB> <figma-url>`.

- **Order is the build order**, and is the same in both arms.
- **`rubric/<name>.md` is required**, or there is nothing to score against.
- **`crd/<name>.md` is optional.** A component without one is built
  identically in both arms and measures the CRD's effect at zero, so leave it
  out of a real trial unless you mean it.
- **Names must match the component stubs committed in `crd-test-builder`**,
  which is where each build writes `src/components/<name>.tsx`. That coupling
  between the two repos is real: add a component here and the stub has to
  exist over there.

## What a trial does

1. Clone a fresh copy of `crd-test-builder` into a temp directory outside this
   repo — **one clone per arm**, not one per component. Every component in
   that arm is built into the same clone, in the listed order, so each build
   lands on a disk that already holds the components before it.
2. For each component, in a fresh Claude session in the clone:

   ```
   claude -p "/build-component <name> <figma-url>"                 # without CRD
   claude -p "/build-component <name> <figma-url> crd/<name>.md"   # with CRD
   ```

   For the with-CRD arm, `crd/<name>.md` is copied into the clone
   **immediately before that component's own build** — so a build sees the
   CRDs of the components already standing in its repo, and nothing for work
   it has not been asked to do yet.
3. After every build, check that session's transcript for any sign it reached
   for this repo — see
   [Web access](docs/keeping-the-builds-honest.md#web-access) — and check that
   the build actually wrote `src/components/<name>.tsx`. There is one such
   check per build, and any one of them failing voids the whole trial: both
   arms, every build. Nothing is assessed and the clones are left in place.
4. Once every build in both arms is done, move `crd/` out of the with-CRD
   clone so both clones look structurally identical to the assessor.
5. Score each candidate's each component blind against `rubric/<name>.md`,
   each in its own fresh Claude session:

   ```
   claude -p "/assess <component> <candidate-dir>/src/components/<name>.tsx <results-file>"
   ```

   The reports land in `results/<stamp>/candidate-{a,b}/<name>.md`
   (gitignored, stays local).
6. Once every assessment is done, move each clone into
   `test_runs/<stamp>/candidate-a` and `candidate-b` for inspection, put
   `crd/` back, and write which arm was which to
   `test_runs/<stamp>/arms.txt`.

`<stamp>` is `trial-YYYYmmdd-HHMMSS`.

## Refreshing the design tokens

Every token a trial needs should already be committed in `crd-test-builder`
before the trial starts, so a build reads them straight from the repo instead
of going to Figma to look them up.

Refreshing them is therefore something you do between runs, never during one:
run `/import-variables` from `crd-test-builder`, which regenerates that repo's
committed token exports and `src/tokens.css` from the Figma file.

Both arms of a trial build against the same tokens, so they are not an
experimental variable; only the CRD is.
