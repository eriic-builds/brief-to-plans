---
slug: example-cli-tool
created: 2026-07-20
updated: 2026-07-24
project_dir: C:\Users\you\Projects\tally\dev-docs\01--example-cli-tool
plan_dir: C:\Users\you\Projects\tally\dev-docs\01--example-cli-tool\Plans
executor: lower-capability model, fresh context per plan
---

# Brief  -  tally, a word-count CLI for markdown folders

## Goal
A single-command CLI called `tally` that reports word and line counts for every
markdown file in a folder, with a total, so drafting progress on a long writing
project can be checked in one second instead of opened file by file. Why now:
the current habit is opening each file and reading the editor's status bar,
which is slow enough that it stops happening and progress goes untracked.
**Success signal:** running `node bin/tally.js ./docs` in the project prints one
row per `.md` file plus a `TOTAL` row, and exits with code `0`.

## Context
- Current state: no tool exists. Counts are read off the editor status bar one
  file at a time.
- Why it is a problem: the check is manual and per-file, so it is skipped, and
  a multi-file draft has no visible progress number.
- Prior decisions already locked:
  - Node.js, no runtime dependencies. The tool must run from a clean checkout
    with `node bin/tally.js` and nothing installed.
  - Output is plain text to stdout. No colour, no TTY detection.
  - Config, when it arrives, is a JSON file. Not YAML, not TOML.
- Non-goals:
  - **No watch mode.** The tool runs, prints, exits. It does not stay resident.
  - No word-count targets, progress bars, or goal tracking.
  - No formats other than markdown.

## Source
Where truth lives. Everything the planner must read before planning.
| Source | Type | Path or link | Status |
|---|---|---|---|
| tally workspace root | repo | `C:\Users\you\Projects\tally` | VERIFIED |
| sample content | folder | `C:\Users\you\Projects\tally\docs` | VERIFIED |

The code lives in the workspace root. This brief and its plans live in
`dev-docs\01--example-cli-tool\`, and every path inside a plan is relative to
the workspace root.

## Expectations
- Deliverables:
  - A runnable CLI entry point at `bin/tally.js`
  - Counting logic separated from output formatting
  - A config loader that reads `.tallyrc.json` when present
- Quality bar: runs on a clean checkout with zero `npm install`. Every failure
  mode prints a one-line message to stderr and exits non-zero rather than
  throwing a stack trace.
- Constraints: Node 18 or later. No runtime dependencies. Windows and POSIX
  paths both work.
- Out of scope: publishing to npm, a test framework, CI.
- Executor tier: lower-capability model, fresh context per plan. Assume it will
  not infer anything not written down.

## Open questions
None outstanding. All decisions above are settled.

Plans for this brief: [Plans/PLANS-INDEX.md](Plans/PLANS-INDEX.md)
