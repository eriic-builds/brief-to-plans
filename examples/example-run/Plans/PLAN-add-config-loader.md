---
plan: PLAN-add-config-loader.md
brief: BRIEF-example-cli-tool.md
brief_updated: 2026-07-24
order: 2 of 2
depends_on: [PLAN-scaffold-cli.md]
reversible: yes
---

# PLAN  -  Add a `.tallyrc.json` config loader

## Goal
When a file named `.tallyrc.json` sits in the project root, `tally` reads two
settings from it — `ignore` (an array of filename glob-free literal names to
skip) and `minWords` (a number below which a file is omitted from the output) —
and applies them before printing. When the file is absent, `tally` behaves
exactly as it did before this plan.

## Context you need
- `tally` is a Node.js CLI that counts words and lines in the `.md` files of a
  folder and prints one row per file plus a `TOTAL` row.
- **No runtime dependencies are allowed.** Use only Node's built-in modules.
  Target runtime is Node 18 or later.
- Config is JSON. Not YAML, not TOML. This was decided before planning and is
  not open.
- The previous plan created `bin/tally.js`, `src/scan.js`, `src/count.js` and
  `src/format.js`. `scanFolder(dir)` returns an array of
  `{ file, words, lines }` sorted by `file`.
- Filtering happens between `scanFolder` and `formatRows`, so `formatRows`
  needs no change and the `TOTAL` row reflects only the rows that survive
  filtering.
- The quality bar from the brief: every failure prints a one-line message to
  stderr and exits non-zero. No stack traces.
- The project root is the workspace root — the folder containing `package.json`.
  All paths below are relative to it, **not** to the `dev-docs` folder this plan
  is stored in. `tally.config.json` sits at the workspace root alongside
  `package.json`, never inside `dev-docs/`.

## Preconditions
- [ ] `PLAN-scaffold-cli.md` is marked `done` in `Plans/PLANS-INDEX.md`.
- [ ] `node bin/tally.js --version` prints `tally 0.1.0` and exits `0`.
- [ ] `src/config.js` does not yet exist.

## Files to touch
| Path | Action | What changes |
|---|---|---|
| `src/config.js` | CREATE | Exports `loadConfig(rootDir)` returning `{ ignore, minWords }` with defaults applied. |
| `src/filter.js` | CREATE | Exports `applyConfig(rows, config)` returning the filtered rows. |
| `bin/tally.js` | MODIFY | Import `loadConfig` and `applyConfig`; call them between `scanFolder` and `formatRows`. |
| `.tallyrc.example.json` | CREATE | A committed example config showing both keys. |

## Steps
1. Create `src/config.js` exporting `export function loadConfig(rootDir)`.
   Build the path with `path.join(rootDir, '.tallyrc.json')`.
2. In `loadConfig`, when `fs.existsSync` on that path returns `false`, return
   the object `{ ignore: [], minWords: 0 }` and do not read the filesystem
   further.
3. In `loadConfig`, when the file exists, read it with
   `fs.readFileSync(configPath, 'utf8')` and parse it with `JSON.parse` inside
   a `try`/`catch`. In the `catch`, throw a new `Error` whose message is
   `invalid .tallyrc.json: ` followed by the caught error's `message`.
4. In `loadConfig`, after parsing, return
   `{ ignore: Array.isArray(parsed.ignore) ? parsed.ignore : [], minWords: typeof parsed.minWords === 'number' ? parsed.minWords : 0 }`.
   Do not throw on a wrong type; fall back to the default for that key only.
5. Create `src/filter.js` exporting
   `export function applyConfig(rows, config)`. Return
   `rows.filter(r => !config.ignore.includes(r.file) && r.words >= config.minWords)`.
   Do not mutate `rows`.
6. In `bin/tally.js`, add imports for `loadConfig` from `../src/config.js` and
   `applyConfig` from `../src/filter.js`.
7. In `bin/tally.js`, inside the existing `try` block, call
   `const config = loadConfig(process.cwd())` before the `scanFolder` call.
8. In `bin/tally.js`, replace the argument passed to `formatRows` so it reads
   `formatRows(applyConfig(rows, config))`. Change nothing else in the file.
9. Create `.tallyrc.example.json` in the project root containing exactly:
   `{ "ignore": ["README.md"], "minWords": 10 }`.

## Edge cases
| Case | Why it bites | What to do |
|---|---|---|
| `JSON.parse` throws on a trailing comma, which humans write constantly in hand-edited JSON | Without step 3's `try`/`catch`, the raw `SyntaxError` reaches the entry point's catch and prints `tally: Unexpected token }` with no mention of the config file, so the user has no idea which file is broken | Step 3 rewraps it as `invalid .tallyrc.json: ...` so the message names the file. |
| `config.ignore` set to a string instead of an array | `Array.prototype.includes` does not exist on a string in the way the filter expects — `"README.md".includes(r.file)` is a substring test that silently matches wrong files and drops them | Step 4's `Array.isArray` check replaces a non-array with `[]`, so a malformed key disables that filter rather than corrupting it. |
| `minWords` present but set to `null` | `r.words >= null` coerces to `r.words >= 0`, which is always true, so the filter appears to work while doing nothing — a silent no-op that looks like correct behaviour | Step 4's `typeof parsed.minWords === 'number'` check rejects `null`, since `typeof null` is `'object'`, and substitutes `0` explicitly. |
| Config is loaded from `process.cwd()` but files are scanned from the positional argument | Running `node bin/tally.js ./docs` from the project root reads config from the root, not from `docs`. Reading it from the scanned folder instead would mean the config moves with the target and cannot be committed once | Load from `process.cwd()` as written in step 7. The config describes the project, not the folder being counted. |
| Every row is filtered out by `minWords` | `formatRows` receives an empty array | `formatRows` already returns `TOTAL  0 words  0 lines` for an empty array. Change nothing in `src/format.js`. |

## Acceptance criteria
- [ ] With no `.tallyrc.json` in the project root, `node bin/tally.js ./docs`
      prints the same output as before this plan and `echo $LASTEXITCODE`
      prints `0`.
- [ ] After writing `{ "ignore": ["README.md"], "minWords": 0 }` to
      `.tallyrc.json`, `node bin/tally.js ./docs` prints no line beginning with
      `README.md`, and the `TOTAL` row's word count is lower than the run
      without the config file.
- [ ] After writing `{ "minWords": 999999 }` to `.tallyrc.json`,
      `node bin/tally.js ./docs` prints exactly one line,
      `TOTAL  0 words  0 lines`, and `echo $LASTEXITCODE` prints `0`.
- [ ] After writing the text `{ "ignore": [], }` to `.tallyrc.json`,
      `node bin/tally.js ./docs` prints one line to stderr beginning with
      `tally: invalid .tallyrc.json:`, prints no stack trace, and
      `echo $LASTEXITCODE` prints `1`.
- [ ] `node -e "import('./src/filter.js').then(m => console.log(m.applyConfig([{file:'a.md',words:5,lines:1}], {ignore:[],minWords:10}).length))"`
      prints `0`.
- [ ] `.tallyrc.example.json` exists in the project root and contains both the
      `ignore` key and the `minWords` key.

## Rollback
Delete `src/config.js`, `src/filter.js` and `.tallyrc.example.json`. In
`bin/tally.js`, remove the two imports added in step 6, remove the `loadConfig`
call added in step 7, and change `formatRows(applyConfig(rows, config))` back
to `formatRows(rows)`. The tool returns to its `PLAN-scaffold-cli.md` state.

## Out of scope
- Do not change `src/count.js`, `src/scan.js` or `src/format.js`.
- Do not add glob or pattern matching to `ignore`. Literal filename matching
  only.
- Do not add command-line flags for `ignore` or `minWords`.
- Do not search parent directories for a config file.
- Do not add a watch mode. The brief lists it as a non-goal.

## When this plan is done
Change this plan's Status cell to `done` in `Plans/PLANS-INDEX.md`, then stop.
Do not begin another plan unless told to.
If any step could not be completed exactly as written, stop and report which
step and why. Do not improvise a substitute.
