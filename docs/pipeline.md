# A full run, stage by stage

Four stages, four artifacts, one folder. This is what actually happens from raw
intent to a finished retrospective.

The same four stages and the same artifact names appear in
[../README.md](../README.md) and in the skill files themselves.

| Stage | Skill | Artifact | Run by |
|---|---|---|---|
| 1 | `/create-brief` | `BRIEF-<slug>.md` | High-capability model |
| 2 | `/create-plans` | `Plans/PLAN-<slug>.md` + `Plans/PLANS-INDEX.md` | High-capability model |
| 3 | — | working code | Lower-capability model |
| 4 | `/dev-report` | `DEV-REPORT-<slug>.html` | High-capability model |

---

## Before you start: nothing to set up

Open whatever workspace the work belongs to and start the session. There are no
path arguments at any stage.

Every run writes into `<workspace root>/dev-docs/<NN>--<slug>/`. If `dev-docs/`
is not there, stage 1 creates it. The number is the highest existing one plus
one, starting at `01`.

**Your code is not moved and not copied.** `dev-docs/` holds only the brief, the
plans and the report. The executor edits the real project in place.

---

## Stage 1  -  `/create-brief`

**What the operator does.** Dumps raw intent. A paragraph, a link, a half-formed
complaint about the current state — whatever they have. They do not need to
structure it.

**What the skill does.**

1. **Harvests** everything already given: the message, referenced files, links,
   prior conversation. It does not ask about anything already answered.
2. **Verifies** every referenced file, folder, repo and URL actually exists. A
   dead path here becomes a hallucinated path in a plan, so unreachable sources
   are marked `UNVERIFIED` rather than dropped.
3. **Asks one batched round of questions** — once, then stops and waits. Only
   about things that materially change the plans: the success signal, non-goals
   if scope could balloon, hard constraints, the executor tier. If nothing
   material is missing, it skips the round entirely.
4. **Writes** `BRIEF-<slug>.md` into a freshly created
   `<workspace root>/dev-docs/<NN>--<slug>/`, creates `Plans/` inside it, and
   records `project_dir` and `plan_dir` in frontmatter as absolute paths.

**What comes out.** One file with Goal, Context, Source, Expectations and Open
questions. Strategic altitude only — no file paths to edit, no step ordering,
no implementation approach, no code.

**Two things that are load-bearing:**

- **Non-goals.** At least one, always. A brief without them produces
  scope-creeping plans.
- **An observable success signal.** "Better performance" is not one. "P95 under
  200ms on the checkout call" is.

**Unknowns stay unknown.** Anything unresolved is written as
`UNKNOWN - needs decision` under Open questions rather than filled with a
plausible guess. Stage 2 surfaces those instead of guessing past them.

**The short form is human-triggered only.** The operator can say "quick brief"
and get Goal, success signal, Non-goals and Source. The model never self-selects
it. It may suggest it; the operator decides.

**Operator's job at the end.** Read the three-line report: the folder path, the
goal in one sentence, and the `UNKNOWN` items. Resolve the unknowns before
stage 2 if you want clean plans.

---

## Stage 2  -  `/create-plans`

This is the stage that determines whether the run succeeds, because everything
after it is literal execution.

### The north star

**The model that executes these plans has no memory, no access to the planning
conversation, less capability than the planner, and will not ask questions.
Anything not written in the plan file does not exist.**

### Two entry paths

**Path A — straight from stage 1.** Run `/create-plans` in the same workspace.
It globs `dev-docs/*/BRIEF-*.md`, finds the one just written, and reads
`plan_dir` from its frontmatter.

**Path B — pointing at a hand-written brief.** Point the skill at a brief file
or the folder containing it. **A hand-written brief with no frontmatter is
normal and must work**, including one that sits outside `dev-docs/`. The skill
never refuses a brief for missing fields; it falls back and says in one line
which folder it resolved to.

Folder resolution, in order:

1. A brief file or project folder Eric pointed at.
2. `<workspace root>/dev-docs/*/BRIEF-*.md`.
3. `BRIEF-*.md` in the folder the session is running in.

Then for the output folder:

1. `plan_dir` from the brief's frontmatter, when present and its parent still
   exists.
2. Otherwise `<the folder containing the brief>/Plans`.

If several `BRIEF-*.md` files match, the skill lists them and asks. It does not
pick one. If `plan_dir` points at a parent that no longer exists, the brief has
been moved: the skill says so and uses the fallback rather than writing to a
stale path.

If `Plans/` already holds plans from a previous run, the skill stops and asks
whether to archive them to `Plans/_archive/<YYYY-MM-DD>/` or add to the set. If
the operator adds to the set, the skill owns the whole set afterwards —
`order: <n> of <total>` is renumbered across every plan and `PLANS-INDEX.md` is
rewritten in full.

**Drift check.** Every plan carries a `brief_updated` stamp. If the brief's
`updated` date is newer, the brief changed after those plans were written and
the skill says so before doing anything else. If the brief has no `updated`
field, drift detection is unavailable and the skill says that once.

### Exploration is a hard gate

No plan is written before the actual source is read. The skill opens the files
listed under Source, traces the code paths the work touches, verifies every path
it intends to put in a plan, and notes what will bite a weaker model: implicit
coupling, non-obvious ordering, shared state, config that must change in two
places, names that look similar but are not, anything that fails silently.

If the source cannot be reached, the skill stops. If exploration reveals the
brief is wrong, infeasible or already partly done, saying so **is** the correct
output — no plans get written.

### Sizing and ranking

One plan = one coherent outcome, verifiable on its own, completable in a single
session, requiring zero judgment calls. Split on a decision point, on two
unrelated subsystems, or when the acceptance criteria cannot all be checked at
the same moment. Merge anything that cannot be verified alone or whose only
value is enabling the next plan. Typical output is 2 to 6.

Ranking is by leverage — unblocks, then irreversibility, then risk burn-down,
with effort as a divisor that never dominates. **Dependency order overrides
leverage order.** A high-leverage plan that depends on a lower one still runs
second.

### What comes out

`Plans/PLAN-<slug>.md` for each plan, each with frontmatter (`brief_updated`,
`order`, `depends_on`, `reversible`), a self-contained Goal, restated Context,
Preconditions, a Files-to-touch table, literal Steps, Edge cases traced to real
observations, runnable Acceptance criteria, Rollback and Out of scope.

Plus `Plans/PLANS-INDEX.md`, which opens with the four-rule protocol addressed
to the executor and a Status column where every cell starts as `pending`.

Then a **cold-read audit**: the skill re-reads each plan as if it had never seen
the conversation, fixes mechanical defects, and reports what changed under
`Audit fixes`. It never suppresses that report — what the audit caught is the
strongest available signal about how good the plans were before it ran.

**Operator's job at the end.** Read the ranked table and the "start with" line.
Check that acceptance criteria name real commands. Resolve anything listed under
`Decisions made for you` if you disagree with the call.

---

## Stage 3  -  Execution

**What the operator does.** Opens a session with a **lower-capability model**
and points it at `dev-docs/<NN>--<slug>/Plans/PLANS-INDEX.md`. Nothing else. No
explanation, no context from the planning conversation — that is the point.

The index tells the executor everything it needs:

1. Work the plans in the order listed.
2. Do not start a plan whose `depends_on` row is not yet `done`.
3. When a plan is finished, change its Status cell to `done`.
4. If a step cannot be done exactly as written, stop and report which step and
   why. Do not improvise a substitute.

**Fresh context per plan** is the intended pattern. Each plan is self-contained
by construction, so a cold session per plan costs nothing and keeps the
executor from carrying forward its own earlier mistakes.

**What comes out.** Working code, and a `PLANS-INDEX.md` whose Status column
shows what was actually attempted.

**Operator's job.** Watch for stops. An executor that halts and names a step is
working correctly — the plan was wrong, not the model. Fix the plan and rerun
that plan in a fresh session; do not answer it in the chat.

**This stage has no skill, so the procedure is the operator's to get right.**
[handoff.md](handoff.md) covers it in full: choosing the model tier, the exact
opening message, the repair loop when the executor stops, resuming after a
partial run, verifying the result yourself, and the anti-patterns that quietly
fake a passing run.

---

## Stage 4  -  `/dev-report`

**What this is for.** Seeing how the run went and learning what the AI actually
did. It is a teaching artifact and a retrospective, **not a validation gate**.
It favours explanation over assurance and never implies the code is verified
correct just because the report reads cleanly.

**What the skill does.** Reads three things in order: `BRIEF-*.md` for the why,
`Plans/` and `PLANS-INDEX.md` for the intended how and what was marked `done`,
and then the actual code as ground truth. Every file it documents, it opens.

Its advantage over a generic code explainer is the brief and the plans. It can
explain **intent**, not just mechanics, and it can see where reality diverged
from the plan. Where implementation and plan disagree, that is a finding to
capture, not an error to smooth over.

If no brief or plans exist, it runs standalone: analyzes the codebase, skips the
drift section, and says in chat that design rationale is inferred rather than
recorded.

**What comes out.** One self-contained `DEV-REPORT-<slug>.html` in the project
folder root — inline CSS, inline JS, inline SVG diagrams, no CDN, no build step,
works from `file://`. Sections run from an executive summary through an
architecture diagram, execution flow, component explorer, dependency tree,
design decisions, code walkthrough, plan-vs-reality drift, lessons and FAQ.

**Operator's job.** Read the drift findings first. That is the part you cannot
get anywhere else.

---

## The whole run in one view

```
<workspace root>/
├── src/ ...                             your code, edited in place at stage 3
└── dev-docs/
    └── 01--auth-rewrite/
        ├── BRIEF-auth-rewrite.md            stage 1
        ├── Plans/
        │   ├── PLANS-INDEX.md               stage 2, executor's entry point
        │   ├── PLAN-extract-token-store.md
        │   └── PLAN-swap-session-middleware.md
        └── DEV-REPORT-auth-rewrite.html     stage 4
```

The next initiative in the same workspace becomes `02--<slug>/`, and so on.

A worked example of stages 1 and 2 sits in
[../examples/example-run](../examples/example-run).
