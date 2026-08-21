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

# Two independent locks for the build session, both scoped to this run:
#
#   sandbox    - enforced by the operating system, so it covers shell
#                commands and anything they start (a node or python script
#                that opens a file itself). Denies this repo and the shared
#                parent of both builds, then allows this build's own
#                directory back in.
#   hook       - a PreToolUse hook covering Claude Code's built-in file
#                tools, which the sandbox does not gate. This has to be a
#                hook rather than permissions.deny rules: deny rules are
#                skipped under --dangerously-skip-permissions, and a probe
#                confirmed a build session could still read this repo and
#                the other candidate through the Read tool with them set.
#
# Both locks are about the local disk. The network is left open — a real
# build might reasonably read up on best practices before writing a
# component, and a trial should look like a real build, including for anyone
# who plugs their own build script into this harness. That does put the
# rubric within reach, since this repo is public with the rubric in it; that
# is handled afterwards instead, by leak_check below. See "Web access" in
# docs/keeping-the-builds-honest.md.
#
# None of this touches Figma: MCP requests are made by Claude Code itself,
# not by a shell command, so they never enter the sandbox. Prep (mise, npm
# ci) runs in this script, outside any sandbox, so the toolchain is already
# installed before the build session starts.
build_settings() { # $1 own build directory, $2 the other build directory
  printf '{"sandbox":{"enabled":true,"filesystem":{"denyRead":["%s","%s"],"allowRead":["%s"]}},"hooks":{"PreToolUse":[{"matcher":"Read|Grep|Glob|Edit|Write|NotebookEdit","hooks":[{"type":"command","command":"%s/bin/deny-paths.sh '"'"'%s'"'"' '"'"'%s'"'"'"}]}]}}' \
    "$ASSESS_REPO" "$RUNS" "$1" \
    "$ASSESS_REPO" "$ASSESS_REPO" "$2"
}

# After the walls, a check that they held. A build session must never touch
# this repo — not over the network, not on disk — and Claude Code records
# every tool call a session makes in its transcript. So if this repo's name
# appears anywhere in a build's transcript, something reached for it and the
# trial is void. One string, because the name is in both the public GitHub URL
# and the local path: a fetch of the rubric puts it there, and so does the
# 'blocked:' message bin/deny-paths.sh emits when it refuses a read.
#
# The session id is ours rather than Claude Code's so we know which transcript
# to read; the glob finds whichever project directory it landed in.
leak_check() { # $1 session id, $2 candidate name
  local transcripts=( "$HOME"/.claude/projects/*/"$1".jsonl )
  if [[ ! -f "${transcripts[0]}" ]]; then
    log "leak check $2: no transcript found for session $1"
    return 1
  fi
  if grep -qa 'crd-test-assessment' "${transcripts[@]}"; then
    log "leak check $2: CONTAMINATED - the build reached for this repo"
    grep -hoa 'crd-test-assessment[^"]\{0,60\}' "${transcripts[@]}" | sort -u >&2
    return 1
  fi
  log "leak check $2: clean"
}

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
    cp "$CRD" "$dir/requirements.md"
    prompt="$prompt requirements.md"
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
