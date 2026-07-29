---
name: "create-plans"
description: "Stage 2 of the brief-to-plans pipeline. Turn a brief into ranked, self-contained Plans/PLAN-<slug>.md files a weaker model can execute literally without asking questions. Explores the source first, sizes the plan count, records exploration-derived edge cases and runnable acceptance criteria. Use when Eric says \"create the plans\", \"create plans\", \"break this into plans\", \"/create-plans\", \"/create-plan\", or points at a BRIEF file."
---

# /create-plans  -  Brief to executable plans

Convert a brief into N ranked, self-contained `PLAN-<slug>.md` files.

## Project folder resolution  -  authoritative

**This section overrides every other folder instruction in this file, including
Step 0.**

Runs live in numbered project folders inside `dev-docs/` at the workspace root:

```
<workspace root>/
└── dev-docs/
    ├── 01--<slug>/
    │   ├── BRIEF-<slug>.md
    │   ├── Plans/          you write here
    │   └── DEV-REPORT-<slug>.html
    └── NN--<slug>/
```

**Find the brief, in this order:**

1. If Eric pointed at a brief file or a project folder, use that.
2. Otherwise glob `<workspace root>/dev-docs/*/BRIEF-*.md`.
3. Otherwise glob `BRIEF-*.md` in the folder the session is running in. A brief
   placed by hand outside `dev-docs/` must still work.
4. If several match, list them with their folder names and ask which. Do not
   pick one.
5. If none match, say so and offer `/create-brief`.

**Resolve the output folder:**

1. `plan_dir` from the brief's frontmatter, when present and its parent exists.
2. Otherwise `<the folder containing the brief>/Plans`.

Create `Plans/` if it is missing. Write plans nowhere else — not to the
workspace root, and not to `dev-docs/` directly.

**The code the plans describe usually lives in the workspace root, not under
`dev-docs/`.** Explore the workspace; write only into the project folder.

## The north star

**The model that executes these plans has no memory, no access to this conversation, less capability than you, and will not ask questions. Anything not written in the plan file does not exist.**

Every rule below follows from that one sentence. When in doubt, ask: could a weaker model in a cold context do this literally, without a single judgment call?

## Where this sits

Stage 1 `/create-brief` (why and what) → **Stage 2 you** (how and when) → Stage 3 executor model (does the work) → Stage 4 `/dev-report` (what got built and why).

Everything lives in one project folder:

```
<project folder>/
├── BRIEF-<slug>.md            stage 1
├── Plans/                     stage 2, you write here
│   ├── PLANS-INDEX.md
│   └── PLAN-<slug>.md ...
└── DEV-REPORT-<slug>.html     stage 4
```

## Step 0  -  Resolve the folder, then load the brief

**Find the brief.**

1. If Eric pointed at a brief file or a folder, use that.
2. Otherwise glob `<workspace root>/dev-docs/*/BRIEF-*.md`.
3. Otherwise look for `BRIEF-*.md` in the folder the session is running in.
4. If several match, list them and ask which. Do not pick one.
5. If none exists, say so and offer `/create-brief`. If Eric declines, proceed from conversation context but state plainly in chat that the plans rest on unrecorded assumptions, and list them.

**Resolve the output folder**, in this order:

1. `plan_dir` from the brief's frontmatter, when present and its parent still exists
2. Otherwise `<the folder containing the brief>/Plans`

**A hand-written brief with no frontmatter is normal and must work.** Never refuse a brief for missing fields — fall back, and say in one line which folder you resolved to. If `plan_dir` points at a parent that no longer exists, the brief has been moved: say so and use the fallback rather than writing to a stale path.

Create `Plans/` if it is missing.

**If `Plans/` already holds PLAN files from a previous run**, stop and ask: archive them to `Plans/_archive/<YYYY-MM-DD>/` and write a fresh set, or add to the existing set. Never silently overwrite a plan the executor may already be partway through.

If Eric chooses to add to the existing set, you own the whole set afterwards: **renumber `order: <n> of <total>` across every plan, old and new, and rewrite `PLANS-INDEX.md` in full.** A set where the numbering disagrees with the index is worse than no numbering.

**Check for brief drift.** Existing plans carry a `brief_updated` stamp. If the brief's `updated` date is newer than that stamp, the brief changed after those plans were written — say so before doing anything else, and name what changed. If the brief carries no `updated` date, drift detection is unavailable; say so once rather than assuming the brief is unchanged.

If the brief has `UNKNOWN - needs decision` items: surface them **before** planning. If an unknown blocks a plan, do not guess it into existence. Either ask Eric in one batched round, or make the decision explicitly and record it in the plan under a `Decision made for you` line so it is visible and reversible.

## Step 1  -  Explore before you write  (hard gate)

**Do not write a single plan before reading the actual source.** The value of this skill is the edge cases only surface through real exploration. Skipping this produces generic plans that are worse than no plans.

- Open the files, repos, and docs listed under Source
- Trace the code paths or content the work touches
- Verify every path you intend to put in a plan actually exists
- Note the things that will bite a weaker model: implicit coupling, non-obvious ordering, shared state, config that must change in two places, naming that looks similar but is not, anything that fails silently

If the source cannot be reached, **stop and say so**. Do not write plans against imagined structure.

If exploration reveals the brief is wrong, infeasible, or already partly done, say that instead of writing plans. An honest "the brief assumes X but X is not true" is the correct output.

## Step 2  -  Decide how many plans

Eric may specify a count (`/create-plans 3`). Otherwise you decide, using this rule:

**One plan = one coherent outcome, verifiable on its own, completable in a single session, requiring zero judgment calls.**

| Signal | Action |
|---|---|
| The work contains a decision point | SPLIT: decide it now, or make it its own plan |
| Touches two unrelated subsystems | SPLIT |
| Acceptance criteria cannot all be checked at the same moment | SPLIT |
| Cannot be verified on its own | MERGE into the plan it serves |
| Its only value is enabling the next plan | MERGE |

Typical output is 2 to 6. If you land on 1, say so plainly. If you exceed 8, the brief is too big: say so, and propose narrowing it rather than shipping fragments.

## Step 3  -  Rank by leverage

Leverage, in order of weight:

1. **Unblocks** - how much other work depends on this landing
2. **Irreversibility** - how expensive it is to get wrong or to do late
3. **Risk burn-down** - how much unknown it removes
4. **Effort** - divides the above, never dominates it

**Dependency order overrides leverage order.** A high-leverage plan that depends on a lower-leverage one still runs second. Never rank a plan ahead of something it requires.

## Step 4  -  Write the plan files

One file per plan, written to `plan_dir` (`<project folder>/Plans`) as `PLAN-<slug>.md`. Slug is task-level kebab-case, distinct from the initiative slug on the brief.

```markdown
---
plan: PLAN-<slug>.md
brief: BRIEF-<initiative>.md
brief_updated: <the brief's updated date, copied verbatim>
order: <n> of <total>
depends_on: [PLAN-<other>.md]   # or: none
reversible: yes | no
---

# PLAN  -  <Title>

## Goal
What is true when this is done. Written so the executor understands the
outcome without reading the brief or anything else.

## Context you need
Three to six bullets. Self-contained. Everything from the brief this plan
depends on, restated here. Assume the reader has never seen the brief.

## Preconditions
- [ ] <verifiable state that must hold before starting>

## Files to touch
| Path | Action | What changes |
|---|---|---|
| <verified path> | CREATE / MODIFY / DELETE | <specific change> |

## Steps
1. <One action. Imperative. Literal. No decisions.>
2. ...

## Edge cases
| Case | Why it bites | What to do |
|---|---|---|
| <observed during exploration> | <concrete consequence> | <exact handling> |

## Acceptance criteria
- [ ] <a command to run and the output that means success>
- [ ] <or a file path and exactly what must be true in it>

## Rollback
How to undo this if it goes wrong. Required when `reversible: no`.

## Out of scope
What this plan must not touch, especially work owned by another plan.

## When this plan is done
Change this plan's Status cell to `done` in `Plans/PLANS-INDEX.md`, then stop.
Do not begin another plan unless told to.
If any step could not be completed exactly as written, stop and report which
step and why. Do not improvise a substitute.
```

Also write `Plans/PLANS-INDEX.md`. This is the executor's entry point when it has no chat history, and Eric's tracking surface for the run.

**The executor never reads this skill file.** Any instruction meant for it must live in the index or inside a plan, or it will not be followed. So the index opens with the protocol, addressed to the executor:

```markdown
## How to run these

1. Work the plans in the order listed below.
2. Do not start a plan whose `depends_on` row is not yet `done`.
3. When a plan is finished, change its Status cell in this table to `done`.
4. If a step cannot be done exactly as written, stop and report which step and
   why. Do not improvise a substitute.

| # | Plan | Depends on | Status |
|---|---|---|---|
| 1 | PLAN-<slug>.md | none | pending |
```

Then the ranked table with leverage rationale, the dependency graph, and the one-line "start here". Every Status cell starts as `pending`, so the folder shows run progress at a glance and `/dev-report` can tell what was actually attempted.

## Writing for a weaker model

Every path is verified to exist, or explicitly marked `CREATE`. A wrong path is the number one cause of executor flailing.

Every edge case is traceable to something you actually observed, with the file or behaviour that revealed it named. **Generic edge cases are banned.** "Handle null input" is filler. "`loadConfig()` returns `{}` not `null` when the file is missing, so the `?? default` on line 42 never fires" is the product.

Every acceptance criterion is something a separate reviewer could check without asking you what you meant. Each one names either a command to run and the output that means success, or a file path and exactly what must be true inside it. "Code is clean" and "it works" are not criteria. If you cannot write a criterion this way, the step is underspecified — fix the step, do not soften the criterion.

**Banned phrases.** Each one forces the reader to make a judgment call it cannot make:

`as appropriate` · `as needed` · `if necessary` · `handle edge cases` · `refactor accordingly` · `update the relevant files` · `make sure it works` · `consider whether` · `clean up` · `etc.`

Where you are tempted to write one of these, make the decision yourself and state the concrete instruction instead.

## Step 5  -  Cold-read audit  (before delivering)

Re-read each plan as if you had never seen this conversation. Fix anything that fails:

1. Does every file path exist, or is it marked `CREATE`?
2. Could a reader with zero context execute step 1 without asking anything?
3. Does every acceptance criterion name a command or a specific file check?
4. Does any step still contain a decision? Make it now and state it.
5. Is every edge case traceable to a real observation?
6. Does the plan stand alone if the brief were deleted?

**Know what this pass is worth.** You are re-reading your own work in the same context that produced it, so it catches mechanical defects — unverified paths, vague criteria, a decision left in a step — and it does not catch your own blind spots. It is not a substitute for review by something that did not write the plans.

**Report what changed**, in one line per fix, under a `Audit fixes` heading. If nothing changed, say `Audit: no changes`. Never suppress it — what the audit caught is the strongest available signal about how good the plans were before it ran.

## Step 6  -  Report to chat

```
## Plans  -  <initiative>

| # | Plan | Leverage | Depends on |
|---|---|---|---|
| 1 | PLAN-<slug>.md | <one line why> | none |

**Start with:** PLAN-<slug>.md  -  <one sentence why this one first>

Written to: <project folder>/Plans/
```

Add a `Decisions made for you` block only if you resolved an `UNKNOWN` from the brief. No closing offer to refine.

## What NOT to do

- Do not write plans before exploring the actual source
- Do not invent file paths, functions, or structure you did not verify
- Do not write generic edge cases to fill the table
- Do not leave a judgment call in a step
- Do not use a banned phrase
- Do not assume the executor read the brief, the index, or any other plan
- Do not pad to hit a plan count, or fragment to look thorough
- Do not rank a plan ahead of its own dependency
- Do not proceed silently past an unresolved `UNKNOWN`
- Do not write an instruction for the executor anywhere except a plan or the index
- Do not suppress the audit report
