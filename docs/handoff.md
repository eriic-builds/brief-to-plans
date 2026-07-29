# Stage 3  -  handing off to the executor

Stages 1 and 2 produce artifacts. Stage 3 produces the actual work, and it is
the only stage with no skill behind it. It is a procedure the operator performs.

This document is **operator-facing**. `Plans/PLANS-INDEX.md` is
**executor-facing**. Keeping those audiences separate is deliberate: the
executor must never need anything that lives outside the folder it was handed.

---

## The one rule

**Open a new session. Do not continue the planning conversation.**

Everything else here is a consequence of that sentence.

`/create-plans` writes for a reader with no memory, no access to the planning
conversation, and no ability to ask questions. That is not a description of the
executor model — it is a *specification the plans were built against*. Stage 3
is where the specification gets tested.

Hand off inside the planning session and the executor inherits the entire
conversation: the exploration, the reasoning, the things you said but never
wrote down. It will perform well. The plans will look excellent. And you will
have learned nothing about whether they are actually self-contained, because
you never ran the experiment.

The failure surfaces weeks later, when someone re-runs a plan cold and it falls
apart. **A warm handoff does not just weaken the test. It fakes a pass.**

---

## Why a weaker model, and how much weaker

The tier gap is the entire economic argument for the pipeline. Planning is
expensive reasoning that compounds — a good plan is reused, audited, and
survives replanning. Execution is cheap literal work that does not compound.
Paying frontier-model rates to follow a numbered list is waste.

But there is a floor. The plans assume the executor can:

- read a file it is pointed at
- create and modify files at literal paths
- run a named command and read the output
- follow a numbered list in order without reordering it
- **stop**, and say which step it stopped on

That last one is the one weak models fail. A model that cannot stop will
improvise, and improvisation is the failure mode the plans exist to prevent.

**Pick the weakest model that can still stop.** If you find yourself repairing
plans that are demonstrably specific, the model is under the floor — move up a
tier rather than padding the plans. Plans written to compensate for a model that
cannot follow instructions are no longer plans; they are code written in prose.

---

## The procedure

### 1. Pick one plan

Open `dev-docs/<NN>--<slug>/Plans/PLANS-INDEX.md` and take the first row whose
Status is `pending` and whose `depends_on` row is already `done`.

Not "the first pending row" — the first *runnable* one. Dependency order is not
advisory. A plan whose dependency has not landed will fail its Preconditions, or
worse, pass them for the wrong reason.

### 2. Start a genuinely new session

In VS Code: open a new chat, then switch the model in the picker. Both, in that
order. Switching the model inside an existing thread does not clear the context
— the new model reads the whole history.

For the Copilot CLI: a new session in the workspace root.

The working directory must be the **workspace root**, not `dev-docs/`. Every
path inside a plan is relative to the project, and the plans say so.

### 3. Send the opening message

```text
Read dev-docs/<NN>--<slug>/Plans/PLANS-INDEX.md and follow its
"How to run these" protocol.

Execute PLAN-<slug>.md only. Stop when its Status cell reads done.
```

That is the whole message. Two sentences, one pointer, one boundary.

**Naming the single plan matters.** Handed the index alone, a capable-enough
executor will often run the entire set in one context — which reintroduces
exactly the cross-plan contamination that per-plan sessions exist to prevent.

### 4. Do not add anything to that message

Every additional sentence is context the plan was supposed to carry. The
temptation is strongest for things that feel like harmless framing:

> "This is for the auth rewrite, so be careful around the session middleware."

If that caution matters, it belongs in the plan's Context or Edge cases. Saying
it in chat means the next person to run this plan does not get it, and you no
longer know whether the plan or your aside carried the run.

**If you cannot start the session without explaining something, the plan has a
defect.** Close the session, fix the plan, start again.

### 5. Repeat with a fresh session per plan

Each plan is self-contained by construction, so a cold session per plan costs
nothing and buys three things:

- **No error carry-forward.** A shortcut taken in plan 1 does not become a
  precedent the model defends in plan 2.
- **Short context.** Weaker models degrade as context grows, and a multi-plan
  run is exactly where they start skipping steps.
- **Attributable drift.** When something is wrong, you know which session did
  it.

Batching several tiny plans into one session is a deliberate exception, not the
default. Take it knowingly, and expect the results to be harder to attribute.

---

## What a good run looks like

The executor reads the index, reads the one plan, checks its Preconditions,
works the Steps in order, checks the Acceptance criteria, flips the Status cell
to `done`, and stops.

**A run that stops early is not a failed run.** A plan that says "stop and
report which step and why" and gets exactly that has worked. The executor
correctly refused to guess. What failed is the plan, and now you know precisely
where.

---

## When the executor stops: the repair loop

This is the part that makes stage 3 a process rather than a single action.

1. **Read which step it stopped on.** The plan told it to name one.
2. **Do not answer in the chat.** Whatever you type there fixes this run and no
   future run, and it contaminates the cold context you were testing.
3. **Open the plan file and fix that step.** Make the decision the step failed
   to make, and write it in literally.
4. **Look for the same defect elsewhere.** A vague step is rarely alone. If step
   4 delegated a judgment call, check whether steps 5 and 6 do the same.
5. **Do not touch the brief.** A step that was underspecified is a stage 2
   defect. Only edit the brief if the *strategy* was wrong — and if you do, bump
   its `updated` date so drift detection catches the stale plans.
6. **Discard the session and start that plan again, cold.**
7. **Write down what you fixed.** This is the single most useful signal you get
   about stage 2 quality, and it evaporates if you do not record it.

Step 6 is the expensive-feeling one and the one worth keeping. Resuming a
poisoned session gives you a result you cannot trust and no information about
whether the repair worked.

---

## When the executor asks a question

**It should not be able to.** Plans are written so there is nothing to ask.

A question is a defect report with a precise location attached. Treat it exactly
like a stop: do not answer, fix the plan, restart.

Answering feels efficient and is the most common way this pipeline quietly
degrades. Each answered question is a decision that lives only in a chat log
nobody will read again, and the plan keeps its bug.

---

## When the executor improvises

The worst case, because nothing announces it. The plans and the index both
instruct the executor to stop rather than substitute, but instruction-following
is probabilistic — a model that decides a step is "basically" satisfied will
move on and mark the plan `done`.

Symptoms worth looking for:

- Files changed that the plan's **Files to touch** table does not list
- A plan marked `done` whose Acceptance criteria you have not actually run
- Output that satisfies the *description* of a step but not its literal text
- Work belonging to a later plan already present

The defence is not a better instruction. It is checking the acceptance criteria
yourself, below.

---

## Resuming after a partial run

If a session dies mid-plan, the Status cell still reads `pending` — correct,
since the plan is not done. Restarting is not always as simple as running it
again.

**Plans are not guaranteed to be re-runnable.** A step that says `CREATE` a file
will fail or duplicate if the file now exists from the abandoned attempt.

So before restarting:

1. Re-read the plan's **Preconditions**. If they no longer hold because of
   partial work, the plan cannot simply be re-run.
2. Use the plan's **Rollback** section to return to the pre-plan state, then
   start cold.
3. If Rollback is missing or insufficient — likely on `reversible: no` plans —
   undo by hand until Preconditions hold again.

This is a rough edge, recorded in [known-gaps.md](known-gaps.md).

---

## Verifying the run  -  this is on you

There is **no validation stage**. The executor self-reports `done` by editing a
table cell, and `/dev-report` explains rather than verifies. See gap 1 in
[known-gaps.md](known-gaps.md).

So after each plan, before marking the run complete:

**Run the Acceptance criteria yourself.** Every one of them names either a
command and its success output, or a file path and what must be true inside it.
They were written that way specifically so this check is mechanical and cheap.
Copy the command, run it, compare the output.

**Skim the diff against the Files to touch table.** Anything changed that the
table does not list is either improvisation or a plan that under-described its
own blast radius. Both are worth knowing.

A useful reinforcement is a **fresh-context reviewer**: a new session, given the
plan and the resulting code and nothing else, asked only whether each acceptance
criterion is met. It cannot rationalise choices it did not make. It is not a
substitute for running the commands.

---

## Anti-patterns

| Anti-pattern | Why it costs you |
|---|---|
| Executing in the planning session | Fakes a pass. The plans are never tested for self-sufficiency. |
| Switching model without a new chat | The new model reads the old history. No context was cleared. |
| Explaining the plan in chat | Moves load-bearing context somewhere the next run cannot see. |
| Answering the executor's question | Patches this run, leaves the plan broken, hides the defect. |
| "Just do your best" past a blocker | Re-delegates the judgment call the plan existed to remove. |
| Running the whole set in one session | Error carry-forward, long context, unattributable drift. |
| Running a plan before its dependency | Preconditions fail, or pass for the wrong reason. |
| Trusting `done` without running the criteria | `done` is the executor's opinion, not a verification. |
| Fixing the brief when a step was vague | Wrong layer. Vague step is a plan defect. |

---

## What the handoff teaches you

Stage 3 is the only honest measurement of stage 2 in the whole pipeline. The
cold-read audit at the end of `/create-plans` catches mechanical defects but
runs in the same context that produced the plans, so it cannot catch the
planner's blind spots. Stage 3 can, because the executor genuinely does not know
what you meant.

Track two numbers across a run:

- **How many plans completed without a stop.** The self-sufficiency rate.
- **What each stop was.** A missing decision, an unverified path, a vague step,
  a wrong assumption about the codebase.

The second is worth more. Stops cluster by cause, and the cause points at which
stage 2 rule was under-applied — usually the exploration gate, or a banned
phrase that slipped through.

If nothing ever stops, either the plans are genuinely good or the executor is
improvising silently. Checking the acceptance criteria is how you tell those
apart, and they are not otherwise distinguishable from the outside.
