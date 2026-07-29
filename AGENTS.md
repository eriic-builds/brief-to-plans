# Agent orientation  -  brief-to-plans

## What this folder is

Reference material plus an installer for the brief-to-plans pipeline: a
four-stage process that separates strategic thinking (`/create-brief`,
`/create-plans`) from cheap execution (a lower-capability model) and closes with
a retrospective (`/dev-report`).

Nothing here is executed by the surrounding repository. There is no build step,
no CI hook, no package manifest and no application code. `install.ps1` and
`install.sh` are run by hand.

## The output contract

Every pipeline run writes into `<workspace root>/dev-docs/<NN>--<slug>/`,
creating `dev-docs/` when missing. Numbers start at `01`, increment from the
highest existing, and are never reused or renumbered. Pipeline artifacts go
there; the code being described stays where it is.

## Scope of this file

**This file governs only this folder.** Any repository-level `AGENTS.md` still
applies and **takes precedence** where the two disagree.

## `skills/` is the canonical source

`skills/<name>/SKILL.md` is the source of truth for all three skills. Other
copies exist:

| Copy | Relationship to `skills/` |
|---|---|
| `~/.copilot/skills/<name>/SKILL.md` | byte-identical, written by the installer |
| `<repo>/.github/skills/<name>/SKILL.md` | byte-identical, only if someone ran `-Scope repo` |

There is **no sync mechanism**. Editing one copy does not update the others;
re-running the installer regenerates them from `skills/`.

**Never write a `<name>.prompt.md` for these skills.** VS Code and the Copilot
CLI both read the same skills folder, so one `SKILL.md` serves both. A prompt
file alongside it registers the command a second time. The installer deletes any
it finds.

**This repository does not check the skills in under `.github/`.** It did once,
and the result was every slash command registering twice — once from the repo,
once from user scope. Do not restore those files; use `install.ps1 -Scope repo`
if a repository genuinely needs its own copies.

These skills originated in an external `_Skills` collection and have since
**diverged from it** — each carries a "Project folder resolution" section that
the originals do not. Do not re-copy from the originals to "restore" them.

## If you change a skill

1. Edit `skills/<name>/SKILL.md` first.
2. Re-run `install.ps1` (or `install.sh`) to regenerate every other copy.
3. Verify with `Get-FileHash -LiteralPath` that the copies match. **Use
   `-LiteralPath`** — this repository's path contains `[` and `]`, which
   PowerShell treats as wildcards, silently matching nothing and producing a
   false MISMATCH.
4. Re-check `templates/` — `BRIEF-template.md`, `PLAN-template.md` and
   `PLANS-INDEX-template.md` are extracted verbatim from the fenced blocks
   inside the skills and must still match. `PLANS-INDEX-template.md` is the
   exception: it is composed from the `## How to run these` block **plus** the
   prose that follows it, so comparing it to any single fenced block reports a
   false mismatch. The `## Plans  -  <initiative>` block in create-plans is the
   Step 6 chat summary, not the index.
7. Keep every `description:` field **under 500 characters**. Scout's loader
   truncates longer ones silently and trigger phrases are lost without warning.

## Naming

- Output root: `<workspace root>/dev-docs/`
- Project folders: `NN--<slug>`, two-digit zero-padded, initiative-level slug
- Briefs: `BRIEF-<slug>.md`, initiative-level slug
- Plans: `PLAN-<slug>.md`, task-level slug — never `PLAN-<n>.md`
- Index: `Plans/PLANS-INDEX.md`
- Report: `DEV-REPORT-<slug>.html`

## Things not to do here

- Do not add build tooling, CI, package manifests or dependencies.
- Do not create symlinks, junctions or hard links for the skill copies.
- Do not run `git init` — this folder is part of a larger repository.
- Do not rewrite the skill bodies to "improve" them; they are copied verbatim
  from an external source of truth.
- Do not write executor instructions into a skill file. The executor never
  reads skill files. Executor instructions belong in `PLANS-INDEX.md` or inside
  a plan.

## Where to read next

- [README.md](README.md) — what the pipeline is
- [INSTALL.md](INSTALL.md) — how the copies reach each tool
- [docs/pipeline.md](docs/pipeline.md) — a full run, stage by stage
- [docs/handoff.md](docs/handoff.md) — stage 3, the one stage with no skill behind it
- [docs/design-decisions.md](docs/design-decisions.md) — why it is shaped this way
- [docs/known-gaps.md](docs/known-gaps.md) — what is missing or unverified
