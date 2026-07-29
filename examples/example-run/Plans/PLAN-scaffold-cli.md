---
plan: PLAN-scaffold-cli.md
brief: BRIEF-example-cli-tool.md
brief_updated: 2026-07-24
order: 1 of 2
depends_on: none
reversible: yes
---

# PLAN  -  Scaffold the tally CLI and counting core

## Goal
`node bin/tally.js ./docs` prints one row per `.md` file in `./docs` with its
word count and line count, followed by a `TOTAL` row, and exits with code `0`.
`node bin/tally.js --version` prints `tally 0.1.0` and exits with code `0`.

## Context you need
- This is a Node.js command-line tool named `tally`. It counts words and lines
  in markdown files so drafting progress across a folder can be checked in one
  command.
- **No runtime dependencies are allowed.** The tool must run from a clean
  checkout with `node bin/tally.js` and no `npm install`. Use only Node's
  built-in modules (`fs`, `path`, `process`).
- Target runtime is Node 18 or later. `fs.readdirSync` with
  `{ withFileTypes: true }` is available.
- Output is plain text on stdout. No colour codes, no TTY detection.
- Counting logic and output formatting are separate modules, because plan 2
  adds a config layer between them.
- The project root is the workspace root — the folder that will contain
  `package.json`. All paths below are relative to it, **not** to the `dev-docs`
  folder this plan is stored in.

## Preconditions
- [ ] `node --version` prints `v18.` or higher.
- [ ] The project root contains a folder named `docs` holding at least one
      `.md` file.
- [ ] `bin/` and `src/` do not yet exist in the project root.

## Files to touch
| Path | Action | What changes |
|---|---|---|
| `package.json` | CREATE | Name `tally`, version `0.1.0`, `"type": "module"`, `"bin": { "tally": "./bin/tally.js" }`. No `dependencies` field. |
| `src/count.js` | CREATE | Exports `countText(text)` returning `{ words, lines }`. |
| `src/scan.js` | CREATE | Exports `scanFolder(dir)` returning an array of `{ file, words, lines }`. |
| `src/format.js` | CREATE | Exports `formatRows(rows)` returning the printable string including the `TOTAL` row. |
| `bin/tally.js` | CREATE | Entry point. Parses one positional argument and `--version`. Calls `scanFolder`, then `formatRows`, then prints. |

## Steps
1. Create `package.json` in the project root with exactly these fields:
   `"name": "tally"`, `"version": "0.1.0"`, `"type": "module"`,
   `"bin": { "tally": "./bin/tally.js" }`. Add no `dependencies` field and no
   `devDependencies` field.
2. Create `src/count.js` exporting `export function countText(text)`. Compute
   `words` as `text.split(/\s+/).filter(Boolean).length`. Compute `lines` as
   `text.split('\n').length`. Return `{ words, lines }`.
3. Create `src/scan.js` exporting `export function scanFolder(dir)`. Read the
   directory with `fs.readdirSync(dir, { withFileTypes: true })`. Keep only
   entries where `entry.isFile()` is true and `path.extname(entry.name)` is
   exactly `.md`. Do not recurse into subdirectories. For each kept entry, read
   the file with `fs.readFileSync(path.join(dir, entry.name), 'utf8')`, call
   `countText`, and collect `{ file: entry.name, words, lines }`. Sort the
   resulting array by `file` ascending using `localeCompare`. Return the array.
4. Create `src/format.js` exporting `export function formatRows(rows)`. Produce
   one line per row in the form `<file>  <words> words  <lines> lines`, then a
   final line `TOTAL  <sumWords> words  <sumLines> lines`. Join the lines with
   `\n`. Return the joined string. When `rows` is empty, return exactly
   `TOTAL  0 words  0 lines`.
5. Create `bin/tally.js` with `#!/usr/bin/env node` as its first line. Import
   `scanFolder` from `../src/scan.js` and `formatRows` from `../src/format.js`.
6. In `bin/tally.js`, read `process.argv.slice(2)`. When the first element is
   `--version`, print `tally 0.1.0` with `console.log` and call
   `process.exit(0)`.
7. In `bin/tally.js`, when there is no positional argument, default the target
   directory to `.`.
8. In `bin/tally.js`, wrap the `scanFolder` call in `try`/`catch`. On success,
   print `formatRows(rows)` with `console.log` and call `process.exit(0)`. On
   any thrown error, print `tally: ` followed by `error.message` with
   `console.error` and call `process.exit(1)`.

## Edge cases
| Case | Why it bites | What to do |
|---|---|---|
| `text.split(/\s+/)` on a file starting with a newline yields a leading empty string | The word count is one too high on every file that begins with a blank line, and markdown files usually do not, so the bug hides until one does | Keep the `.filter(Boolean)` in step 2. It removes both leading and trailing empty entries. |
| `text.split('\n').length` counts a trailing newline as an extra line | A file ending with a newline reports one more line than an editor shows, so the number silently disagrees with the status bar it is replacing | Accept the off-by-one and document it in `src/count.js` as a one-line comment stating that a trailing newline counts as a line. Do not special-case it. |
| `path.extname` returns `.MD` on an uppercase filename, which is not equal to `.md` | Uppercase-named files are skipped without any message, so the total is quietly wrong | Compare `path.extname(entry.name).toLowerCase()` to `.md` in step 3. |
| `fs.readdirSync` throws `ENOENT` when the target folder does not exist | Without the `try`/`catch` from step 8, Node prints a full stack trace and exits with code `1`, which fails the quality bar of a one-line message | The `try`/`catch` in step 8 turns it into `tally: ENOENT: no such file or directory, scandir '<dir>'` on stderr. |
| A subfolder named `notes.md` is a directory, not a file | `readFileSync` throws `EISDIR` and the whole run aborts on what should be skipped | The `entry.isFile()` check in step 3 excludes it before the extension check runs. |

## Acceptance criteria
- [ ] `node bin/tally.js --version` prints exactly `tally 0.1.0` and
      `echo $LASTEXITCODE` prints `0`.
- [ ] `node bin/tally.js ./docs` prints one line per `.md` file in `docs`,
      then a final line beginning with `TOTAL`, and `echo $LASTEXITCODE` prints
      `0`.
- [ ] `node bin/tally.js ./no-such-folder` prints a single line to stderr
      starting with `tally: ENOENT`, prints no stack trace, and
      `echo $LASTEXITCODE` prints `1`.
- [ ] `node -e "import('./src/count.js').then(m => console.log(JSON.stringify(m.countText('one two three'))))"`
      prints `{"words":3,"lines":1}`.
- [ ] `package.json` contains no `dependencies` key and no `devDependencies`
      key.

## Rollback
Delete `package.json`, `bin/` and `src/` from the project root. Nothing else
was created and no existing file was modified.

## Out of scope
- Do not create `src/config.js` or read any `.tallyrc.json` file. Config
  loading belongs to `PLAN-add-config-loader.md`.
- Do not add recursion into subdirectories.
- Do not add a test framework, a linter, or CI configuration.
- Do not publish to npm.

## When this plan is done
Change this plan's Status cell to `done` in `Plans/PLANS-INDEX.md`, then stop.
Do not begin another plan unless told to.
If any step could not be completed exactly as written, stop and report which
step and why. Do not improvise a substitute.
