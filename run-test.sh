#!/usr/bin/env bash
# Run one trial of the CRD test: build the component twice (with and
# without the CRD), assess both candidates blind, print the results and
# which candidate had the CRD.
#
# Each build runs in its own temporary directory outside this repo, walled
# off from the other build and from this repo. See "Keeping the builds
# honest" in docs/keeping-the-builds-honest.md.
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "usage: $0 <component>" >&2
  echo "  <component>  name of a CRD in crd/ (e.g. badge)" >&2
  exit 1
fi

log() { printf '[%4ds] %s\n' "$SECONDS" "$*" >&2; }

# HTTPS rather than SSH: crd-test-builder is public, so anyone who forks this
# repo can run a trial without having SSH access set up.
BUILDER_REPO="https://github.com/masofon/crd-test-builder.git"

ASSESS_REPO="$(cd "$(dirname "$0")" && pwd)"

COMPONENT="$1"
CRD="$ASSESS_REPO/crd/$COMPONENT.md"
if [[ ! -f "$CRD" ]]; then
  echo "no CRD for '$COMPONENT' (looked for $CRD)" >&2
  exit 1
fi
if [[ ! -f "$ASSESS_REPO/rubric/$COMPONENT.md" ]]; then
  echo "no rubric for '$COMPONENT' (expected $ASSESS_REPO/rubric/$COMPONENT.md)" >&2
  exit 1
fi

# The Figma component URL is the 'design:' field of the CRD's frontmatter.
FIGMA_URL="$(sed -n 's|^design:[[:space:]]*\(https://[^[:space:]#]*\).*|\1|p' "$CRD" | head -1)"
if [[ -z "$FIGMA_URL" ]]; then
  echo "no Figma URL in $CRD: its frontmatter needs a 'design: https://...' field" >&2
  exit 1
fi
STAMP="$COMPONENT-$(date +%Y%m%d-%H%M%S)"

# Both builds happen outside this repo, under one shared parent so a single
# deny rule covers every candidate. Each build then gets its own directory
# allowed back in. The candidates are moved into test_runs/ once both
# assessments are done.
RUNS="$(mktemp -d "${TMPDIR:-/tmp}/crd-test-$STAMP-XXXXXX")"
CLONE_A="$RUNS/a"
CLONE_B="$RUNS/b"
KEEP="$ASSESS_REPO/test_runs/$STAMP"
RESULTS="$ASSESS_REPO/results/$STAMP"
mkdir -p "$RESULTS"

CLAUDE_CODE_MODEL="sonnet"
CLAUDE_CODE_EFFORT="medium"

if (( RANDOM % 2 )); then
  WITH_CRD="candidate-a"; WITHOUT_CRD="candidate-b"
else
  WITH_CRD="candidate-b"; WITHOUT_CRD="candidate-a"
fi

dir_for() { # $1 candidate name -> its build directory
  case "$1" in
    candidate-a) printf '%s' "$CLONE_A" ;;
    candidate-b) printf '%s' "$CLONE_B" ;;
    *) echo "unknown candidate '$1'" >&2; return 1 ;;
  esac
}

other_dir_for() { # $1 candidate name -> the *other* candidate's directory
  case "$1" in
    candidate-a) printf '%s' "$CLONE_B" ;;
    candidate-b) printf '%s' "$CLONE_A" ;;
    *) echo "unknown candidate '$1'" >&2; return 1 ;;
  esac
}

# The two isolation primitives a build depends on, build_settings() and
# leak_check(). bin/check-isolation.sh sources the same file, so the check
# exercises exactly what a trial runs rather than a copy that can drift.
# shellcheck source=bin/isolation.sh
source "$ASSESS_REPO/bin/isolation.sh"

build() { # $1 candidate name, $2 "with" | "without"
  local dir other settings sid
  dir="$(dir_for "$1")"
  other="$(other_dir_for "$1")"
  settings="$(build_settings "$dir" "$other")"
  sid="$(uuidgen | tr '[:upper:]' '[:lower:]')"
  log "prep $1: start"
  git clone --quiet "$BUILDER_REPO" "$dir"
  rm -rf "$dir/.claude/skills/import-variables"
  local prompt="/build-component $FIGMA_URL"
  if [[ "$2" == "with" ]]; then
    mkdir -p "$dir/crd"
    cp "$CRD" "$dir/crd/$COMPONENT.md"
    prompt="$prompt crd/$COMPONENT.md"
  fi
  (cd "$dir" && mise trust --quiet && mise install --quiet && mise x -- npm ci --silent)
  log "prep $1: done"
  log "build $1 ($2 CRD): start"
  (cd "$dir" && \
    claude --model "$CLAUDE_CODE_MODEL" --effort "$CLAUDE_CODE_EFFORT" \
      --session-id "$sid" \
      -p "$prompt" \
      --settings "$settings" \
      --dangerously-skip-permissions --mcp-config .mcp.json)
  log "build $1 ($2 CRD): done"
  # A contaminated build must never be scored, so stop before assessing. The
  # candidates stay in "$RUNS" for inspection rather than being cleaned up.
  if ! leak_check "$sid" "$1"; then
    echo "trial void: see the build directory at $RUNS" >&2
    exit 1
  fi
}

# The assessor reads this repo's rubric and both candidates, but gets no
# MCP servers and no network: the rubric is self-contained, so a live
# design read would be a second variable alongside the CRD.
assess() { # $1 candidate name
  local dir
  dir="$(dir_for "$1")"
  log "assess $1: start"
  (cd "$ASSESS_REPO" && \
    claude --model "$CLAUDE_CODE_MODEL" --effort "$CLAUDE_CODE_EFFORT" \
      -p "/assess $COMPONENT $dir/src/Component.tsx $RESULTS/$1/assessment.md" \
      --dangerously-skip-permissions)
  log "assess $1: done"
}

log "run start: component $COMPONENT, figma $FIGMA_URL, build dir $RUNS, CRD arm $WITH_CRD"
build "$WITH_CRD" with
build "$WITHOUT_CRD" without
assess candidate-a
assess candidate-b

# Both builds and both assessments are done, so the candidates can come back
# into the repo for inspection. test_runs/ is gitignored.
mkdir -p "$KEEP"
mv "$CLONE_A" "$KEEP/candidate-a"
mv "$CLONE_B" "$KEEP/candidate-b"
printf '%s: with CRD\n%s: without CRD\n' "$WITH_CRD" "$WITHOUT_CRD" > "$KEEP/arms.txt"
rmdir "$RUNS"
log "run done"

echo
echo "=== Arms ==="
echo "$WITH_CRD: with CRD"
echo "$WITHOUT_CRD: without CRD"
echo
echo "=== candidate-a ==="
# cat "$RESULTS/candidate-a/assessment.md"
echo "$RESULTS/candidate-a/assessment.md"
echo
echo "=== candidate-b ==="
# cat "$RESULTS/candidate-b/assessment.md"
echo "$RESULTS/candidate-b/assessment.md"
echo
echo "Candidates kept in $KEEP"
