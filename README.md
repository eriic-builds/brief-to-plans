# Brief-to-Plans Pipeline

Three slash commands for GitHub Copilot: `/create-brief`, `/create-plans`,
`/dev-report`.

## Install by pasting a link

Paste this into GitHub Copilot Chat, in VS Code or the CLI:

```text
Install the skills from https://github.com/eriic-builds/brief-to-plans
```

The agent reads the block below and copies three files. Nothing is executed.
Reload the VS Code window afterwards.

<!-- agent-install:start -->
> **Instructions for an AI agent asked to install these skills.**
>
> This install is three file copies. Do not run a script, and do not clone.
>
> Fetch each URL and save its contents verbatim to the matching path under the
> user's home directory:
>
> | Fetch | Save to |
> |---|---|
> | `https://raw.githubusercontent.com/eriic-builds/brief-to-plans/main/skills/create-brief/SKILL.md` | `~/.copilot/skills/create-brief/SKILL.md` |
> | `https://raw.githubusercontent.com/eriic-builds/brief-to-plans/main/skills/create-plans/SKILL.md` | `~/.copilot/skills/create-plans/SKILL.md` |
> | `https://raw.githubusercontent.com/eriic-builds/brief-to-plans/main/skills/dev-report/SKILL.md` | `~/.copilot/skills/dev-report/SKILL.md` |
>
> On Windows `~` is `%USERPROFILE%`. Create folders as needed. Write UTF-8
> without a BOM.
>
> **Do not** also write `<name>.prompt.md` files, and **do not** also copy these
> into a repository's `.github/skills/`. Either one registers each slash command
> a second time, and the user sees duplicates.
>
> Then tell the user to reload the VS Code window and try `/create-brief`.
<!-- agent-install:end -->

Prefer to run it yourself? See [INSTALL.md](INSTALL.md) for the script, the
uninstall, and the repo-scope option.

---

**A brief answers why and what. A plan answers how and when.**

Every run lands in a numbered project folder under `dev-docs/` at the root of
whatever workspace you are in. `dev-docs/` is created if it is not there.

```
<workspace root>/
└── dev-docs/
    ├── 01--<slug>/
    │   ├── BRIEF-<slug>.md            stage 1  /create-brief
    │   ├── Plans/                     stage 2  /create-plans
    │   │   ├── PLANS-INDEX.md
    │   │   └── PLAN-<slug>.md ...
    │   └── DEV-REPORT-<slug>.html     stage 4  /dev-report
    ├── 02--<slug>/
    └── NN--<slug>/
```

Stage 3 is the executor model doing the work. It produces code in the workspace,
not an artifact in `dev-docs/`, and it reads `Plans/PLANS-INDEX.md` as its only
entry point.

That why/what versus how/when split is the whole idea. A brief is strategic: it
states the destination and the constraints, and it survives a change of
implementation approach. A plan is tactical: it states the route, and it does
not survive that change. Keeping them apart lets expensive reasoning be spent
where it compounds and cheap execution be spent where it does not.

> This folder is **reference material plus an installer**. Nothing in it is
> executed by the surrounding repository — there is no build step, no CI hook,
> and no application code. Run `install.ps1` (or `install.sh`) to make the three
> skills available in every workspace. See [INSTALL.md](INSTALL.md).

## The four stages

| Stage | Skill | Artifact | Run by |
|---|---|---|---|
| 1 | `/create-brief` | `BRIEF-<slug>.md` | High-capability model |
| 2 | `/create-plans` | `Plans/PLAN-<slug>.md` + `Plans/PLANS-INDEX.md` | High-capability model |
| 3 | — | working code | Lower-capability model |
| 4 | `/dev-report` | `DEV-REPORT-<slug>.html` | High-capability model |

The governing constraint on stage 2 is that the executing model **has no memory,
no access to the planning conversation, and will not ask questions.** Anything
absent from the plan file does not exist. Every rule in `/create-plans` follows
from that.

Stage 4 is a **learning artifact, not a sign-off gate.** The operator reads it
to see how the run went and what the AI actually did.

## Folder resolution rules

- **The output root is `<workspace root>/dev-docs/`**, where the workspace root
  is the top-level folder open in the editor. It is created when missing.
- Stage 1 creates the next numbered folder `NN--<slug>/` inside `dev-docs/`.
  The number is the highest existing leading number plus one, starting at `01`,
  zero-padded to two digits. Numbers are never reused or renumbered.
- Stage 2 finds the brief by globbing `dev-docs/*/BRIEF-*.md`, then falling back
  to `BRIEF-*.md` in the session folder. If several match, it asks rather than
  picking one.
- The plans folder is `plan_dir` from the brief's frontmatter when that field is
  present and its parent still exists. Otherwise it is
  `<the brief's folder>/Plans`.
- **A hand-written brief with no frontmatter is normal and must work.** Every
  stage falls back to filesystem conventions, so no stage may refuse a brief
  for missing fields — including a brief placed outside `dev-docs/`.
- **Your code stays where it is.** Only pipeline artifacts go in `dev-docs/`.
  The executor edits the real project; the brief, plans and report describe it
  from the side.

## Quickstart

No clone needed — the installer fetches the three skill files itself:

```powershell
irm https://raw.githubusercontent.com/eriic-builds/brief-to-plans/main/install.ps1 -OutFile install.ps1
pwsh -File install.ps1
```

From a clone, run it in place instead:

```powershell
pwsh -File install.ps1        # macOS and Linux: ./install.sh
```

Reload the VS Code window. That is the whole setup — the skills now work in
every workspace, not just this one. Nothing is checked in under `.github/`,
deliberately: a copy there *and* at user scope registers every slash command
twice. Use `install.ps1 -Scope repo -RepoRoot <path>` if a repository needs its
own copies instead.

Then, from any workspace:

```text
/create-brief    turn raw intent into dev-docs/NN--<slug>/BRIEF-<slug>.md
/create-plans    read the brief, explore the source, write ranked PLAN files
                 and PLANS-INDEX.md into that folder's Plans/
                 --- hand off to the executor model here ---
/dev-report      read the brief, the plans and the code, write
                 DEV-REPORT-<slug>.html into the same folder
```

Stage 3 sits between stages 2 and 4 and has no skill — it is a procedure you
perform. Open a **new session** with a lower-capability model, point it at
`dev-docs/NN--<slug>/Plans/PLANS-INDEX.md`, and name the one plan it should run.
The new session is the whole point: continuing the planning conversation lets
the executor inherit context the plans were supposed to carry, which does not
just weaken the test, it fakes a pass.
[docs/handoff.md](docs/handoff.md) is the full procedure.

## What is in this folder

| Path | What it is |
|---|---|
| [skills/](skills) | The canonical copies of the three skills |
| [install.ps1](install.ps1) / [install.sh](install.sh) | Installs the skills at user scope, for every workspace |
| [templates/](templates) | The brief, plan and index templates, extracted from the skills |
| [docs/pipeline.md](docs/pipeline.md) | A prose walkthrough of a full run |
| [docs/handoff.md](docs/handoff.md) | Stage 3 in full: handing off to a lower-capability model |
| [docs/design-decisions.md](docs/design-decisions.md) | Why the pipeline is shaped this way |
| [docs/known-gaps.md](docs/known-gaps.md) | What is missing, untested or unverified |
| [examples/example-run/](examples/example-run) | A worked example for a small CLI tool |
| [INSTALL.md](INSTALL.md) | How the skills reach VS Code and the Copilot CLI |
| [AGENTS.md](AGENTS.md) | Orientation for an AI agent opening this folder |
