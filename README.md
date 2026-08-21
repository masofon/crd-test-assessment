# crd-test-assessment

Assessment side of the CRD effectiveness test: does giving a builder agent a
Component Requirements Doc (CRD) alongside the Figma component produce a
better React component than the Figma component alone?

This repo holds per-component rubrics (`rubric/`), the scoring skill
(`.claude/skills/assess/`), and per-component CRDs (`crd/`, each CRD's
frontmatter carrying its Figma component URL). The builder must never see this
repo; the CRD crosses over only by an explicit file copy. See
[Keeping the builds honest](docs/keeping-the-builds-honest.md) for how that is
enforced.

## Running a trial

`./run-test.sh <component>` runs a whole trial end to end — both builds, both
assessments, and prints which candidate had the CRD. `<component>` is the name
of a CRD in `crd/` (e.g. `badge`). A component needs both `crd/<component>.md`
and `rubric/<component>.md`, and the CRD's frontmatter must carry the Figma
component URL in its `design:` field — the run errors out if it doesn't.

```
./run-test.sh badge
```

The steps it automates:

1. Clone a fresh copy of `crd-test-builder` into a temp directory outside this
   repo, one per arm.
2. For the with-CRD arm only, copy `crd/<component>.md` from here into the
   clone as `requirements.md`.
3. In the clone, run a fresh Claude session with the same prompt every
   trial:

   ```
   claude -p "/build-component <figma-url>"                    # without CRD
   claude -p "/build-component <figma-url> requirements.md"    # with CRD
   ```

4. Check that build's transcript for any sign it reached for this repo, and
   abandon the trial if it did — see
   [Web access](docs/keeping-the-builds-honest.md#web-access).
5. Score each candidate blind against `rubric/<component>.md`, each in its own
   fresh Claude session:

   ```
   claude -p "/assess <component> <candidate-dir>/src/Component.tsx <figma-url> <results-file>"
   ```

   The reports land in `results/<stamp>/` (gitignored, stays local).
6. Once both assessments are done, move each clone into
   `test_runs/<stamp>/candidate-a` and `candidate-b` for inspection, and write
   which arm was which to `test_runs/<stamp>/arms.txt`.

## Refreshing the design tokens

Every token a trial needs should already be committed in `crd-test-builder`
before the trial starts, so a build reads them straight from the repo instead
of going to Figma to look them up.

Refreshing them is therefore something you do between runs, never during one:
run `/import-variables` from `crd-test-builder`, which regenerates that repo's
committed token exports and `src/tokens.css` from the Figma file.

Both arms of a trial build against the same tokens, so they are not an
experimental variable; only the CRD is.
