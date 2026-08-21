#!/usr/bin/env bash
# PreToolUse hook: block Claude Code's built-in file tools from touching any
# path under the prefixes given as arguments.
#
# The Bash sandbox cannot see these tools, and permissions.deny rules are
# skipped under --dangerously-skip-permissions, so this hook is what stops a
# build session reading the assessment repo or the other candidate. Exit 2
# blocks the call and shows the message to the model.
#
# Only the local disk is walled off here. Web access is deliberately left
# open — see "Web access" in docs/keeping-the-builds-honest.md — and is
# checked after the fact
# instead, by the leak check in run-test.sh.
set -euo pipefail

payload="$(cat)"

# Compare every path-shaped field the built-in file tools use, resolved to an
# absolute real path, against each denied prefix (also resolved, so a symlink
# or a /tmp -> /private/tmp alias can't slip past).
verdict="$(
  python3 - "$payload" "$@" <<'PY'
import json, os, sys

payload, prefixes = sys.argv[1], sys.argv[2:]
ti = (json.loads(payload).get("tool_input") or {})
real = lambda p: os.path.realpath(os.path.abspath(p))
denied = [real(p) for p in prefixes]

for key in ("file_path", "path", "notebook_path"):
    v = ti.get(key)
    if not isinstance(v, str) or not v:
        continue
    target = real(v)
    for prefix in denied:
        if target == prefix or target.startswith(prefix + os.sep):
            print(target)
            sys.exit(0)
PY
)"

if [[ -n "$verdict" ]]; then
  echo "blocked: $verdict is outside this build's own directory" >&2
  exit 2
fi

exit 0
