#!/usr/bin/env bash
# The two isolation primitives a trial depends on, in one place so that
# bin/check-isolation.sh exercises exactly what run-test.sh uses rather than
# a copy that can drift.
#
# Sourced, never run. The caller must have set, before calling either:
#   ASSESS_REPO  absolute path to this repo
#   RUNS         the shared parent directory holding both builds
#   log()        a logging function
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  echo "$0 is meant to be sourced, not run" >&2
  exit 1
fi

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
