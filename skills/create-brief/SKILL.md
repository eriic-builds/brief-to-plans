---
name: "create-brief"
description: "Stage 1 of the brief-to-plans pipeline. Capture strategic intent as BRIEF-<slug>.md with Goal, Context, Source, Expectations. Use when Eric says \"create a brief\", \"write a brief\", \"brief this up\", \"/create-brief\", or drops raw intent for a project he wants to hand off. Not for tactical steps, file-level detail, or task decomposition - that is /create-plans."
---

# /create-brief  -  Strategic intent capture

Turn raw intent into one structured `BRIEF-<slug>.md`. Why and what only.

## Project folder resolution  -  authoritative

**This section overrides every other folder instruction in this file.**

Every run lives in its own numbered project folder inside a `dev-docs/` folder
at the workspace root:

```
<workspace root>/
└── dev-docs/
    ├── 01--<slug>/
    │   ├── BRIEF-<slug>.md
    │   ├── Plans/
    │   │   ├── PLANS-INDEX.md
    │   │   └── PLAN-<slug>.md ...
    │   └── DEV-REPORT-<slug>.html
    ├── 02--<slug>/
    └── NN--<slug>/
```

**Resolve `dev-docs/`:**

1. The workspace root is the top-level folder currently open in the editor. In a
   multi-root workspace, use the root the active file belongs to; if that is
   ambiguous, list the roots and ask.
2. `dev-docs/` sits directly in the workspace root: `<workspace root>/dev-docs`.
3. **If `dev-docs/` does not exist, create it.** Do not ask first. Do not search
   parent directories for an existing one.
4. Never write pipeline artifacts to the workspace root itself.

**Number the new project folder:**

1. List the immediate subfolders of `dev-docs/` whose names start with two or
   more digits followed by `--`.
2. Take the highest leading number and add 1. When none match, start at `1`.
3. Zero-pad to two digits (`01`, `02` ... `99`). From 100 up, use three digits.
4. Name the folder `<NN>--<slug>`, reusing the brief's slug.
5. Create it, create `Plans/` inside it, and record the absolute paths as
   `project_dir` and `plan_dir` in the brief's frontmatter.

The numbers record creation order and nothing else. Never renumber an existing
folder, and never reuse a number freed by a deleted one.

## Where this sits

| Stage | Artifact | Written by | Answers |
|---|---|---|---|
| 1 | `BRIEF-<slug>.md` | high-capability model (you) | Why and what. Strategic. |
| 2 | `Plans/PLAN-<slug>.md` x N | `/create-plans` | How and when. Tactical. |
| 3 | working output | lower-capability executor model | Does the work. |
| 4 | `DEV-REPORT-<slug>.html` | `/dev-report` | What got built and why. |

The brief is the input to `/create-plans`. It is not a plan. Every gap left here becomes a guess made downstream by a weaker model.

## Project folder

Everything for one initiative lives in one folder, so a run can be tracked end to end:

```
<project folder>/
├── BRIEF-<slug>.md            stage 1, this skill
├── Plans/                     stage 2, /create-plans
│   ├── PLANS-INDEX.md
│   └── PLAN-<slug>.md ...
└── DEV-REPORT-<slug>.html     stage 4, /dev-report
```

This skill owns the folder contract. It creates `Plans/` and records both paths in frontmatter so later stages never have to guess.

## Hard boundary

**Do not solve the problem in the brief.** No file paths to edit, no step ordering, no implementation approach, no code. If you catch yourself writing "first do X then Y", that belongs in a plan. The brief states the destination and the constraints on getting there, never the route.

## Proportionality

The brief scales with blast radius. **You never decide to skip it.**

Eric can ask for a short brief explicitly — "quick brief", "short brief", "keep it light". Only then: write Goal, the success signal, Non-goals, and Source, drop the rest, and say in one line which sections you dropped.

Never self-select the short form. The expensive step is the one that gets skipped, and a model given the option to skip it will take that option nearly every time. You may *suggest* the short form when the work looks small; Eric decides.

## Step 1  -  Harvest what's already given

Read everything Eric provided: the message, referenced files, links, prior conversation. Extract into the four sections. Do not ask about anything already answered.

If he referenced files, folders, repos, or URLs, **verify they exist** before listing them as Source. A dead path in the brief becomes a hallucinated path in a plan. Mark unreachable sources as `UNVERIFIED`.

## Step 2  -  One batched gap round

Ask about gaps **once**, batched, then stop and wait. Never drip-feed questions across turns.

Only ask when the answer materially changes the plans. Ask about:
- The success signal, if there is no way to tell whether this worked
- Non-goals, if the scope could plausibly balloon
- Hard constraints (deadline, tech, budget, policy) that would invalidate an otherwise-good approach
- The executor tier, if unstated

Never ask about: preferences you can infer, anything cosmetic, or anything a plan could reasonably decide.

If nothing material is missing, skip this step entirely and write the brief.

## Step 3  -  Write the file

**Resolve the folder using "Project folder resolution" above.** Create
`<workspace root>/dev-docs/` if it is missing, then create the next numbered
`<NN>--<slug>/` folder inside it. If Eric named a folder explicitly, use that
instead. Never ask merely because he did not specify — the next numbered folder
under `dev-docs/` is the answer.

Then:

1. Write `BRIEF-<slug>.md` in the project folder root
2. Create the `Plans/` subfolder if it does not exist
3. Record `project_dir` and `plan_dir` in frontmatter as absolute paths

Slug is kebab-case, short, initiative-level (not task-level): `auth-rewrite`, not `fix-login-bug-and-add-tests`. The same slug names the dev-report at stage 4, so pick one that will still read correctly at the end of the run.

If the folder already contains a `BRIEF-*.md`, stop and ask whether to supersede it or start a new project folder. Do not silently write a second brief beside it.

## Template

```markdown
---
slug: <kebab-case>
created: <YYYY-MM-DD>
updated: <YYYY-MM-DD>
project_dir: <absolute path to the project folder>
plan_dir: <absolute path to project_dir/Plans>
executor: <who or what runs the plans, e.g. "lower-capability model, fresh context per plan">
---

# Brief  -  <Title>

## Goal
What outcome is true when this is done. Two to four sentences.
Include why now, and the one signal that proves it worked.

## Context
- Current state: what exists today
- Why it is a problem: the friction being removed
- Prior decisions already locked: things a plan must not relitigate
- Non-goals: what this explicitly does not cover

## Source
Where truth lives. Everything the planner must read before planning.
| Source | Type | Path or link | Status |
|---|---|---|---|
| <name> | repo / file / doc / chat / person | <path> | VERIFIED / UNVERIFIED |

## Expectations
- Deliverables: the artifacts that must exist at the end
- Quality bar: what "good" means here
- Constraints: tech, time, policy, budget, compatibility
- Out of scope: work that must not happen under this brief
- Executor tier: how much judgment the downstream model can be trusted with

## Open questions
Unresolved decisions, each marked `UNKNOWN - needs decision`.
Leave these visible. /create-plans surfaces them rather than guessing.
```

## Rules

1. **Never invent facts.** If something is unknown, write `UNKNOWN - needs decision` under Open questions. A confident wrong brief is worse than a thin honest one.
2. **Non-goals are load-bearing.** A brief without them produces scope-creeping plans. Always write at least one.
3. **The success signal must be observable.** "Better performance" is not a signal. "P95 under 200ms on the checkout call" is.
4. **Source paths get verified, not assumed.** Check they exist. Mark what you could not reach.
5. **Prior decisions get recorded.** Anything already settled goes in Context so plans do not reopen it.
6. **Strategic altitude only.** If a line could not survive a change of implementation approach, it does not belong in the brief.
7. **One brief, one initiative.** If the intent contains two unrelated outcomes, say so and write two briefs.
8. **Bump `updated` on every edit.** `/create-plans` compares it against the `brief_updated` stamp on existing plans to detect drift. A brief edited after plans were written, without the date moving, produces stale plans that nothing flags.

## Output to chat

After writing, report in three lines: the project folder path, the goal in one sentence, and any `UNKNOWN` items that need Eric's decision before `/create-plans` can run cleanly.

Then offer exactly one next step: run `/create-plans` against this folder.

## Pipeline

`/create-brief` → `/create-plans` → executor model → `/dev-report`

## What NOT to do

- Do not write implementation steps, file-level edits, or ordering
- Do not ask questions in more than one round
- Do not fill an unknown with a plausible guess
- Do not pad Context with background Eric already knows
- Do not produce a brief for two unrelated initiatives
- Do not skip Non-goals or the success signal
