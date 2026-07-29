# Design decisions

Each entry records a choice and the reasoning behind it, so the choice can be
argued with rather than inherited.

---

## Stage 3 is a cold session per plan, and the operator never answers in chat

**Decision.** The handoff opens a genuinely new session — new chat *and* a
switched model — for each individual plan, with an opening message that points
at the index, names one plan, and says nothing else. When the executor stops or
asks a question, the operator edits the plan file and restarts cold rather than
replying.

**Why.** `/create-plans` writes for a reader with no memory and no access to the
planning conversation. That is a specification, and stage 3 is the only place it
is ever tested. Executing inside the planning session lets the executor inherit
the exploration and the unwritten reasoning, so the plans perform well for a
reason that will not exist next time. That does not merely weaken the test — it
returns a false pass, and the defect surfaces much later when someone re-runs
the plan cold.

The same logic drives the no-answering rule. A reply in chat fixes one run and
leaves the plan broken, moving a load-bearing decision into a transcript nobody
reads again. A stop is a defect report with a precise line number attached; the
repair belongs in the file.

Per-plan rather than per-run because plans are self-contained by construction,
so cold context costs nothing and buys three things: no carry-forward of an
earlier shortcut, short context for a model that degrades as context grows, and
drift that can be attributed to a specific session.

**Deliberately excluded:** any enforcement. Nothing prevents a warm handoff. The
procedure is documented in [handoff.md](handoff.md) and relies on the operator,
which is a real weakness — the failure it guards against is invisible from the
outside.

---

## Executor instructions are addressed to the executor, operator instructions are not

**Decision.** `Plans/PLANS-INDEX.md` and the plan files speak to the executor.
[handoff.md](handoff.md) speaks to the operator. Neither document carries the
other's content.

**Why.** The executor must never need anything outside the folder it was handed;
mixing operator procedure into the index would put text in front of it that it
cannot act on and might try to. Equally, the operator's failure modes — warm
sessions, explaining in chat, trusting `done` — are invisible to the executor and
cannot be fixed by instructing it better.

---

## Artifacts land in `dev-docs/NN--<slug>/`, not beside the code

**Decision.** Every run writes into `<workspace root>/dev-docs/<NN>--<slug>/`,
created on demand. Numbers start at `01`, increment from the highest existing,
and are never reused or renumbered.

**Why.** The earlier rule — "the folder the session is running in" — works only
when the operator remembers to `cd` somewhere sensible first. In practice a
session starts at a repository root, so briefs and plans scattered into whatever
folder happened to be current, mixed in with source. One fixed, predictable
location per workspace means the skills need no path argument, `/create-plans`
can find a brief by globbing one directory, and a workspace accumulates a
legible history of initiatives instead of loose files.

Numbering rather than dates because the ordering that matters is "which
initiative came first", and a two-digit prefix sorts correctly in every file
explorer without parsing. Numbers are never reused because a plan or report may
cite `03--<slug>` long after `03` was deleted, and silently reassigning it would
point that citation at unrelated work.

**Deliberately excluded:** the code itself. `dev-docs/` holds only the brief,
the plans and the report. The executor edits the real project in place. Moving
source into a docs folder would break every relative path in every plan.

---

## Distribution is one mechanism with two scopes

**Decision.** The skills ship as an installer only. Nothing is checked in under
`.github/`. User scope is the default; `-Scope repo` generates repository-local
copies on demand for anyone who wants clone-and-go.

**Why.** This reverses an earlier decision, and the reversal is the interesting
part. Shipping *both* repository files and an installer looked like it served
two audiences — clone-and-go for visitors, portability for the owner. In
practice both are discovered simultaneously, so anyone who did both got every
slash command registered twice. Two distribution channels for one command is a
defect, and no amount of documentation makes a duplicated command list correct.

User scope wins the default because it is strictly more capable: it works in
every workspace, which is the entire reason to install anything. Repo scope
loses nothing by being generated rather than committed — it is one flag away,
and generating it from the canonical copy removes a class of drift that
committed copies guarantee.

The installer is a plain script rather than a package manifest because adding a
dependency manager to a folder of markdown would be a worse trade than the
manual sync it avoids. It has a `-WhatIf` mode and an `-Uninstall` mode because
a script that writes into a user's home directory should be inspectable and
reversible before it is trusted, and it warns when it finds the other scope
already installed because that is the one configuration that reproduces the bug
this decision exists to fix.

---

## The brief and the plan are separate documents

**Decision.** Stage 1 produces a brief. Stage 2 produces plans. Never one
document.

**Why.** Collapsing them yields a document that is simultaneously too vague to
execute and too specific to reason about. Strategic material — why now, what
counts as done, what is out of scope — has to stay stable while the approach
changes. Tactical material — which file, which order, which command — has to be
literal enough for a weaker model to follow without a judgment call. A single
document either dilutes the strategy with file paths or starves the execution
of detail. Splitting them also means an approach can be thrown away and
replanned without touching the brief.

---

## Stage 2 exploration is a hard gate

**Decision.** `/create-plans` does not write a single plan before reading the
actual source. If the source cannot be reached, it stops.

**Why.** Unexplored plans produce generic edge cases and invented file paths.
They look authoritative while being wrong, which is the worst possible failure
mode — the executor follows them confidently into nothing. "Handle null input"
is filler. "`loadConfig()` returns `{}` not `null` when the file is missing, so
the `?? default` on line 42 never fires" is the entire product, and it only
exists because someone opened the file. A wrong path is the number one cause of
executor flailing.

---

## Dependency order overrides leverage order

**Decision.** A high-leverage plan that depends on a lower-leverage one still
runs second.

**Why.** Leverage ranking answers "what is worth doing first". Dependency
answers "what is possible first". Possibility wins. Ranking a plan ahead of its
own dependency guarantees the executor either stops on an unmet precondition or,
worse, improvises the dependency badly to unblock itself.

---

## Judgment-delegating phrases are banned in plans

**Decision.** These phrases may not appear in a plan:

`as appropriate` · `as needed` · `if necessary` · `handle edge cases` ·
`refactor accordingly` · `update the relevant files` · `make sure it works` ·
`consider whether` · `clean up` · `etc.`

**Why.** Each one silently hands a decision to the model least equipped to make
it. The planner has read the source, has the brief, and has the strongest
reasoning available in the pipeline. The executor has none of that. "Update the
relevant files" is the planner declining to name the files it already knows.
Where the temptation appears, the correct move is to make the decision now and
write the concrete instruction.

---

## Executor instructions live in `PLANS-INDEX.md` and inside plans, never in the skill file

**Decision.** Any instruction meant for the executor is written into the index
or into a plan.

**Why.** **The executor never reads the skill file.** It is handed a folder, not
a toolchain. An instruction placed in `/create-plans` reaches the planner and
stops there. This is why the index opens with the four-rule protocol addressed
directly to the executor, and why every plan repeats its own "when this plan is
done" instruction rather than relying on the index having been read.

---

## The short-brief form is human-triggered only

**Decision.** The model may suggest the short form. It may never select it.

**Why.** A model allowed to skip the expensive step will skip it — nearly every
time, and always with a reasonable-sounding justification. The brief is the
expensive step, and it is also the step whose absence is invisible until stage 3
produces the wrong thing. Making the decision human keeps the escape hatch
available without making it the default.

---

## Acceptance criteria must be mechanically checkable

**Decision.** Every acceptance criterion names either a runnable command and the
output that means success, or a file path and exactly what must be true inside
it.

**Why.** A criterion exists to be checked by someone who was not in the
planning conversation. "Code is clean" and "it works" cannot be checked by
anyone, which makes them decorative. The rule also acts as a design constraint
on the step above it: if a criterion cannot be written this way, the step is
underspecified. The fix is to sharpen the step, never to soften the criterion.

---

## Frontmatter is a convenience, not a requirement

**Decision.** Every stage falls back to filesystem conventions when frontmatter
is missing. A hand-written brief with no frontmatter must work, including one
that sits outside `dev-docs/`.

**Why.** Frontmatter makes the happy path fast — `plan_dir` means stage 2 never
guesses. But requiring it would make the pipeline unusable for the most common
real entry point: someone wrote a brief by hand, or pasted one in, and wants
plans from it. Refusing that brief for a missing field would be the pipeline
protecting its own conventions at the operator's expense. So `plan_dir` falls
back to `<the brief's folder>/Plans`, the brief is found by globbing
`dev-docs/*/BRIEF-*.md` and then the session folder, and the slug is derived
from the filename or the folder name.

---

## Stage 4 is a retrospective, not a validation gate

**Decision.** `/dev-report` explains; it does not certify.

**Why.** The operator reads it to see how the run went and to learn what the AI
actually did. Framing it as sign-off would create exactly the wrong incentive:
a report that reads cleanly would start to feel like evidence the code is
correct, which it is not. So the skill favours explanation over assurance,
treats plan-versus-reality divergence as a finding rather than an error to
smooth over, and never implies verification it did not perform. See
[known-gaps.md](known-gaps.md) — the absence of a real validation stage is a
known gap, not something stage 4 quietly covers.

---

## One `SKILL.md` per scope, copied rather than linked

**Decision.** A single `SKILL.md` per skill per scope. No `.prompt.md`
companions, no symlinks, junctions or hard links.

**Why.** This corrects an assumption that was simply wrong. The original design
treated VS Code and the Copilot CLI as needing different formats — a
`.prompt.md` for one, a `SKILL.md` for the other — and installed both. In fact
both tools read the same skills folder, so every skill registered twice from a
single scope. The evidence was sitting in plain sight: every other skill already
installed on this machine has a `SKILL.md` and no prompt file, and they all work
in both tools.

Prompt files remain a real VS Code feature; they are simply redundant here, and
redundant registration is indistinguishable from a bug at the point of use.

Copies rather than links because junctions have previously produced duplicate
entries in skill listings — different loaders resolve them differently and some
walk both the link and the target. Having just removed one duplication bug,
reintroducing a subtler one would be a poor trade.

The cost is manual sync: editing one copy does not update the others. The
installer removes most of that cost by regenerating every copy from the
canonical one on demand, which is also why no copy is committed. `skills/` is
canonical. This remains a real, ongoing cost — see gap 6 in
[known-gaps.md](known-gaps.md).
