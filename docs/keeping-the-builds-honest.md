# Keeping the builds honest

The test only means something if each builder works from what we gave it and
nothing else. Three things would quietly ruin a trial:

- A builder reading this repo. The rubric it will be marked against lives in
  `rubric/`, and every CRD lives in `crd/`. A builder that read either would
  score well for the wrong reason.
- The without-CRD builder reading the with-CRD builder's work. The with-CRD
  build has the CRD sitting in its folder as `requirements.md`, so a peek
  there hands the "blind" arm the very document the test is meant to withhold.
- A builder fetching any of it off the web. This repo is public, rubric and
  all, so "don't read the folder" is not enough on its own — the same text is
  a search away.

The first two are shut off at the source: a builder cannot reach this repo or
its sibling on disk, however hard it tries. The third isn't, on purpose — see
[Web access](#web-access).
None of it has happened so far, and every trial now proves that for itself
rather than us taking the transcripts on trust.

## Why good behaviour isn't enough

The builds run with `--dangerously-skip-permissions`. Normally Claude Code
stops and asks a human before it does anything significant, but nobody is
sitting there during an automated run, so the flag turns the asking off. That
also turns off the thing that would otherwise stop a builder wandering into a
folder it shouldn't. So we put the walls somewhere the flag can't reach.

## Three walls

**1. The builds happen outside this repo.** Each trial creates a fresh
temporary folder — something like `/var/folders/…/crd-test-badge-…/` — with
one build in `a/` and the other in `b/`. Nothing about a build's surroundings
hints that this repo exists. This isn't a lock in itself, but it removes the
accidental routes: a listing of the folder above, a search that spreads
wider than intended, or Claude Code picking up instruction files from parent
folders. The candidates are moved back into `test_runs/` at the very end,
after both builds and both assessments have finished, so nothing is in reach
while it could still matter.

**2. An operating-system lock (the "sandbox").** For each build, the script
tells the operating system: this session may not read this repo, and may not
read the shared temporary folder — except for its own `a/` or `b/` folder,
which is allowed back in. Because the operating system enforces this rather
than Claude Code, it holds no matter what the session tries, and it covers
commands the session runs *and* any program those commands start. A script
that opened the rubric file directly would be refused, the same as a plain
`cat` of it.

**3. A check on Claude's own reading tools.** The sandbox covers shell
commands, but Claude reads most files through its own built-in tools, and
those don't go through the operating system in the same way — so the sandbox
doesn't stop them. Each build therefore also runs a small script,
`bin/deny-paths.sh`, that Claude Code calls *before* every file the session
tries to read or write. The script is told two folders: this repo, and the
other build's folder. If the file is inside either one, the read is refused
and Claude is told why.

The obvious way to write this wall would be Claude Code's built-in "deny"
rules, and that turns out not to work: those rules are switched off by the
same `--dangerously-skip-permissions` flag. We checked, rather than assumed —
a test session with deny rules in place read both this repo's rubric and the
other build's copy of the CRD without difficulty. The pre-check script is run
regardless of that flag, and blocked all of it.

Walls 2 and 3 overlap on purpose. Each alone leaves a gap: the sandbox
doesn't cover Claude's built-in tools, and the pre-check script doesn't cover
a program that opens a file by itself.

Both walls are about the local disk. The web is handled differently, and the
next section is about why.

## Web access

Builds have full web access. That is a deliberate choice, and it is the one
place where this test detects a problem rather than preventing it.

An earlier version cut the network off entirely, which is certainly safer:
this repo is public, rubric and all, so a builder that can reach the internet
can reach the document it is being marked against. But a real developer
building a component might well read up on best practices first, and a builder
that cannot is not doing the job we are trying to measure. That matters most
for anyone who clones this and plugs in their own build script: a harness that
silently removes the web changes what is being tested.

Narrowing the web instead of cutting it — allowing npm but blocking
`github.com` — doesn't survive contact either. Once the text is public it is
also in search results, caches and mirrors, and a blocklist is a game of
catch-up you lose quietly, without ever learning a trial was spoiled.

So the web stays open, and the trial checks afterwards whether it was misused.

Claude Code keeps a transcript of each session: every tool call it made and
everything that came back. A build has no honest reason to mention this repo,
so after each build `run-test.sh` searches that build's transcript for one
string — the repo's name:

```
crd-test-assessment
```

If it finds it, the trial stops there and nothing is assessed. A spoiled build
must never be given a score.

One string is enough because that name is in every route to the rubric.
Fetched from the web it arrives as `github.com/…/crd-test-assessment/…`,
whether by `WebFetch`, by `WebSearch` results, or by `curl` in the shell — and
the URL is written to the transcript before the request goes out, so an
attempt is caught even if it fails. Read from the disk, the attempt shows up
as the `blocked:` message from wall 3, which names the path it refused.

What this doesn't catch is a builder that deliberately hides its tracks —
assembling the URL from pieces so the name never appears literally. Nothing
short of logging the network itself would, and a builder scheming to find its
own marking scheme isn't the failure this test is guarding against. What it is
guarding against is the realistic one: a builder searching the web for help
with a badge component and landing on this repo by accident. That leaves the
name in the transcript every time.

Figma is unaffected by any of this. It is reached over a different channel
(MCP) that Claude Code handles itself rather than through the shell, so it
never touches the sandbox at all.

## Checking the walls

You can run the isolation check yourself, and it's worth re-running whenever
Claude Code updates, since the behaviour the walls depend on isn't something
we control:

```
./bin/check-isolation.sh
```

It builds the same folder layout a trial uses, plants a fake CRD where the
other build's would be, and asks a Claude session to try eight things with the
real settings applied: reading this repo's rubric, reading the other build's
CRD two different ways, fetching a page from the shell, `WebFetch`,
`WebSearch`, and finally its own file. The four disk reads outside its own
folder have to come back blocked, and the rest have to succeed — walls that
blocked those would break the builds instead of protecting them.

It then checks the other half, that the leak check works: the probe session
was handed a path inside this repo, so a working check has to spot the name in
its transcript. No Figma access or component build is involved, so the whole
thing takes about a minute.

## What is deliberately not locked down

The assessor. It runs as its own separate session, after the builds are
finished, and it has to read the rubric and both candidates to do its job. It
never writes to a candidate, and no builder is running at the same time.

The assessor is also never told which arm was which — that mapping is written
to `arms.txt` only after both assessments are complete.
