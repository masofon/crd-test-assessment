#!/usr/bin/env bash
# Run one trial of the CRD test: build every component in component-list.tsv
# twice — once into a clone that gets the CRDs, once into a clone that does
# not — assess all of them blind, and print which candidate had the CRDs.
#
# The components are built cumulatively: one clone per arm, and each build
# lands on a disk that already holds the components before it. So the trial
# asks whether a CRD helps across a growing component set, not whether it
# helps on one component in isolation.
#
# Each arm builds in its own temporary directory outside this repo, walled
# off from the other arm and from this repo. See "Keeping the builds
# honest" in docs/keeping-the-builds-honest.md.
set -euo pipefail

log() { printf '[%4ds] %s\n' "$SECONDS" "$*" >&2; }

# HTTPS rather than SSH: crd-test-builder is public, so anyone who forks this
# repo can run a trial without having SSH access set up.
BUILDER_REPO="https://github.com/masofon/crd-test-builder.git"

ASSESS_REPO="$(cd "$(dirname "$0")" && pwd)"
COMPONENT_LIST="$ASSESS_REPO/component-list.tsv"

DRY_RUN=0
if [[ "${1:-}" == "-n" ]]; then DRY_RUN=1; shift; fi
if [[ $# -gt 0 ]]; then
  echo "usage: $0 [-n]" >&2
  echo "  -n  print the plan, build nothing" >&2
  exit 1
fi

# The two isolation primitives a build depends on, build_settings() and
# leak_check(). bin/check-isolation.sh sources the same file, so the check
# exercises exactly what a trial runs rather than a copy that can drift.
# shellcheck source=bin/isolation.sh
source "$ASSESS_REPO/bin/isolation.sh"

# component-list.tsv is the component list, the build order and the Figma
# URLs: one component per line, <name> <TAB> <figma-url>.
COMPONENTS=()
FIGMA_URLS=()
while read -r name url; do
  [[ -n "$name" ]] || continue
  COMPONENTS+=("$name")
  FIGMA_URLS+=("$url")
done < "$COMPONENT_LIST"

STAMP="trial-$(date +%Y%m%d-%H%M%S)"

CLAUDE_CODE_MODEL="sonnet"
CLAUDE_CODE_EFFORT="medium"

if (( RANDOM % 2 )); then
  WITH_CRD="candidate-a"; WITHOUT_CRD="candidate-b"
else
  WITH_CRD="candidate-b"; WITHOUT_CRD="candidate-a"
fi

if (( DRY_RUN )); then
  echo "stamp: $STAMP"
  echo "$WITH_CRD: with CRD"
  echo "$WITHOUT_CRD: without CRD"
  echo
  echo "build order:"
  for i in "${!COMPONENTS[@]}"; do
    crd="no CRD"
    [[ -f "$ASSESS_REPO/crd/${COMPONENTS[$i]}.md" ]] && crd="crd/${COMPONENTS[$i]}.md"
    printf '  %d. %-20s %s  [%s]\n' "$((i + 1))" "${COMPONENTS[$i]}" "${FIGMA_URLS[$i]}" "$crd"
  done
  echo
  echo "would run $(( ${#COMPONENTS[@]} * 2 )) builds and $(( ${#COMPONENTS[@]} * 2 )) assessments"
  exit 0
fi

# Both arms build outside this repo, under one shared parent so a single deny
# rule covers every candidate. Each arm then gets its own directory allowed
# back in. The candidates are moved into test_runs/ once every assessment is
# done.
RUNS="$(mktemp -d "${TMPDIR:-/tmp}/crd-test-$STAMP-XXXXXX")"
CLONE_A="$RUNS/a"
CLONE_B="$RUNS/b"
KEEP="$ASSESS_REPO/test_runs/$STAMP"
RESULTS="$ASSESS_REPO/results/$STAMP"
HIDDEN_CRDS="$RUNS/hidden-crds"
mkdir -p "$RESULTS"

trap 'rc=$?; (( rc )) && echo "trial aborted (exit $rc); clones left at $RUNS" >&2' EXIT

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

# One clone per arm, not per component, so npm ci runs twice a trial rather
# than once per build.
prepare_clone() { # $1 candidate name
  local dir
  dir="$(dir_for "$1")"
  log "prep $1: start"
  git clone --quiet "$BUILDER_REPO" "$dir"
  rm -rf "$dir/.claude/skills/import-variables"
  (cd "$dir" && mise trust --quiet && mise install --quiet && mise x -- npm ci --silent)
  log "prep $1: done"
}

# One component, one fresh session, into a clone that already holds the
# components built before it. Must be called from the main shell, never
# inside $(...) or a pipeline, or its exit 1 will not end the trial.
build_one() { # $1 candidate, $2 with|without, $3 component, $4 figma url
  local dir other settings sid prompt shared
  dir="$(dir_for "$1")"
  other="$(other_dir_for "$1")"
  settings="$(build_settings "$dir" "$other")"
  sid="$(uuidgen | tr '[:upper:]' '[:lower:]')"

  prompt="/build-component $3 $4"
  if [[ "$2" == "with" && -f "$ASSESS_REPO/crd/$3.md" ]]; then
    # Copied in immediately before this component's build, never earlier: a
    # build sees the CRDs of the components already standing in its repo,
    # and nothing for work it has not been asked to do yet. The path stays
    # relative, so no absolute temp path enters the prompt.
    mkdir -p "$dir/crd"
    cp "$ASSESS_REPO/crd/$3.md" "$dir/crd/$3.md"
    prompt="$prompt crd/$3.md"
  fi

  # The session id is logged because with two sessions per component you need
  # it to find a transcript afterwards.
  log "build $1 $3 ($2 CRD): start, session $sid"
  (cd "$dir" && \
    claude --model "$CLAUDE_CODE_MODEL" --effort "$CLAUDE_CODE_EFFORT" \
      --session-id "$sid" \
      -p "$prompt" \
      --settings "$settings" \
      --dangerously-skip-permissions --mcp-config .mcp.json)
  log "build $1 $3 ($2 CRD): done"

  # A contaminated build must never be scored, and a trial is one
  # experiment: a leak anywhere voids every build in it, not just this one.
  if ! leak_check "$sid" "$1/$3"; then
    echo "trial void: see the build directories at $RUNS" >&2
    exit 1
  fi

  # A filename slip should fail here, not as a baffling /assess result an
  # hour later. The committed stub is unmodified if the build wrote elsewhere.
  if git -C "$dir" diff --quiet -- "src/components/$3.tsx"; then
    echo "build $1 $3: src/components/$3.tsx is still the committed stub, trial void" >&2
    echo "see the build directories at $RUNS" >&2
    exit 1
  fi

  # Files shared by every component in the clone. A build has no business
  # touching them, but this is logged rather than restored: a later component
  # may already depend on the change, so restoring would break the build the
  # guard was meant to protect. The log is what lets a human attribute the
  # disqualification the assessor will report against every component here.
  shared="$(git -C "$dir" status --porcelain -- src/tokens.css src/main.tsx index.html)"
  if [[ -n "$shared" ]]; then
    while IFS= read -r line; do
      log "WARN: $3 modified ${line##* }"
    done <<<"$shared"
  fi
}

# The with-CRD clone would otherwise carry crd/ while the assessor reads it —
# a directory of CRDs and a git status that lists them. Set aside for the
# duration so both clones look structurally identical to every assessor
# session, and put back once the clone has moved to $KEEP.
hide_crds() { # $1 candidate name
  local dir
  dir="$(dir_for "$1")"
  [[ -d "$dir/crd" ]] || return 0
  mkdir -p "$HIDDEN_CRDS"
  mv "$dir/crd" "$HIDDEN_CRDS/$1"
  log "hid $1/crd for the assessments"
}

restore_crds() { # $1 candidate; call after the clone has moved to $KEEP
  [[ -d "$HIDDEN_CRDS/$1" ]] || return 0
  mv "$HIDDEN_CRDS/$1" "$KEEP/$1/crd"
}

# The assessor reads this repo's rubric and one candidate file, but gets no
# MCP servers: the rubric is self-contained, so a live design read would be a
# second variable alongside the CRD. It must run from this repo, because the
# skill resolves rubric/$component.md relative to its working directory.
assess_one() { # $1 candidate name, $2 component
  local dir
  dir="$(dir_for "$1")"
  log "assess $1 $2: start"
  (cd "$ASSESS_REPO" && \
    claude --model "$CLAUDE_CODE_MODEL" --effort "$CLAUDE_CODE_EFFORT" \
      -p "/assess $2 $dir/src/components/$2.tsx $RESULTS/$1/$2.md" \
      --dangerously-skip-permissions)
  log "assess $1 $2: done"
}

log "=== Claude Code: model=$CLAUDE_CODE_MODEL effort=$CLAUDE_CODE_EFFORT ==="
log "run start: ${#COMPONENTS[@]} components, build dir $RUNS, CRD arm $WITH_CRD"

prepare_clone candidate-a
prepare_clone candidate-b

# Arm at a time: a clone accumulates its components in the listed order.
for candidate in "$WITH_CRD" "$WITHOUT_CRD"; do
  mode=with; [[ "$candidate" == "$WITHOUT_CRD" ]] && mode=without
  for i in "${!COMPONENTS[@]}"; do
    build_one "$candidate" "$mode" "${COMPONENTS[$i]}" "${FIGMA_URLS[$i]}"
  done
done

hide_crds candidate-a
hide_crds candidate-b

# Every assessment happens after every build, so no assessor sees a
# half-built clone and no builder runs while one is being read.
for name in "${COMPONENTS[@]}"; do
  assess_one candidate-a "$name"
  assess_one candidate-b "$name"
done

# Every build and every assessment is done, so the candidates can come back
# into the repo for inspection. test_runs/ is gitignored.
mkdir -p "$KEEP"
mv "$CLONE_A" "$KEEP/candidate-a"
mv "$CLONE_B" "$KEEP/candidate-b"
restore_crds candidate-a
restore_crds candidate-b
rmdir "$HIDDEN_CRDS" 2>/dev/null || true
# The reports never name the arms, so this file is the only durable record of
# the mapping. Written only once every assessment has finished.
printf '%s: with CRD\n%s: without CRD\n' "$WITH_CRD" "$WITHOUT_CRD" > "$KEEP/arms.txt"
rmdir "$RUNS"
log "run done"

echo
echo "=== Arms ==="
echo "$WITH_CRD: with CRD"
echo "$WITHOUT_CRD: without CRD"
for name in "${COMPONENTS[@]}"; do
  echo
  echo "=== $name ==="
  echo "candidate-a: $RESULTS/candidate-a/$name.md"
  echo "candidate-b: $RESULTS/candidate-b/$name.md"
done
echo
echo "Candidates kept in $KEEP"
