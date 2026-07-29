# Known gaps

Real limitations, not hypotheticals. Read this before trusting the pipeline
with anything that matters.

---

## 1. No validation stage

Nothing checks executor output against the plans' acceptance criteria.

The executor self-reports `done` by editing a Status cell. Stage 4 explains what
happened rather than verifying it — by design, since it is a retrospective and
not a gate. So the pipeline has a clean-looking finish line that nothing
enforces.

**The missing piece is a stage 3.5: a fresh-context reviewer** that reads the
plans and the resulting code with no memory of either being produced, and checks
each acceptance criterion by actually running the named command or opening the
named file. Fresh context matters — the same session that produced the work
cannot audit it, for the same reason the stage 2 cold-read audit catches
mechanical defects but not blind spots.

**Until that exists, verification rests entirely with the human.** The
"Verifying the run" section of [handoff.md](handoff.md) sets out what that
actually requires: running each acceptance criterion yourself and diffing
against the plan's **Files to touch** table.

---

## 2. `/dev-report` has no secrets-exclusion rule

The skill inlines real code into a shareable, self-contained HTML file, and it
contains **no instruction to exclude** `.env` files, API keys, tokens,
connection strings, credentials or config secrets.

The report is designed to be opened through OneDrive and SharePoint in-browser
preview, which means the default destination is a shared surface.

**Mitigation until the skill is fixed:** read the generated HTML before sharing
it, and do not run `/dev-report` on a project folder containing live
credentials.

---

## 3. Zero end-to-end runs

The pipeline has never been run start to finish on a real multi-plan
initiative.

Specifically untested:

- **Plan sizing.** The split/merge rules and the "typical output is 2 to 6"
  guidance are reasoned, not observed.
- **Leverage ranking.** Whether the four-factor ordering produces a sequence an
  executor can actually follow is unknown.
- **The drift and archive paths.** Re-running `/create-plans` over an existing
  `Plans/` folder, renumbering `order: <n> of <total>`, and archiving to
  `Plans/_archive/<YYYY-MM-DD>/` have not been exercised.

The example in [../examples/example-run](../examples/example-run) is
illustrative, not a record of a real run.

---

## 4. Skill descriptions are capped at 500 characters

Scout's loader truncates any `description:` field longer than 500 characters
**silently**. There is no warning and no error.

The consequence is subtle and bad: the trigger phrases at the end of a
description are the ones that get cut, so the skill stops firing on the phrases
you thought you had registered, and nothing tells you why.

**Rule: keep every `description:` field under 500 characters.** Check after any
edit to a skill's frontmatter.

---

## 5. Brief drift detection is best-effort

Drift detection compares the brief's `updated` date against each plan's
`brief_updated` stamp.

It fails in two ways:

- **A brief with no `updated` field cannot be checked at all.** The skill says
  so once, then proceeds.
- **A brief edited without bumping `updated` is invisible.** The stamps agree,
  so the plans look current when they are stale.

Both failure modes depend on human discipline. There is no content hash and no
change detection beyond the date.

---

## 6. Two copies of each skill, and no drift detection

Each skill exists in two places once installed:

```
02--Brief-to-Plans-Pipeline/skills/<name>/SKILL.md   canonical
~/.copilot/skills/<name>/SKILL.md                    installed, both tools
```

`install.ps1` regenerates the installed copy from the canonical one, so they
stay correct **as long as it is re-run after every edit**. Nothing enforces
that, and no CI checks it.

Running `-Scope repo` adds a third copy under a repository's `.github/skills/`,
which is why installing at both scopes is called out as a defect rather than an
option.

The drift is silent and asymmetric — you will usually notice that the tool you
are currently using has the old version, and not notice that the others
disagree. The only reliable check is comparing hashes, as described in
[../INSTALL.md](../INSTALL.md).

---

## 7. The skills have diverged from their upstream originals

These three skills were copied from an external `_Skills` collection and then
edited here to add the `dev-docs/<NN>--<slug>/` folder contract. The copies in
this repository are **no longer byte-identical to those originals**.

Re-copying from upstream would silently revert the folder contract, and every
document here that describes `dev-docs/` would become wrong without anything
failing. There is no marker in the files themselves recording the divergence
beyond the "Project folder resolution" section each one now carries.

---

## 8. The numbering rule has a race and a rename hazard

The next project number is computed by listing `dev-docs/` and adding one to the
highest prefix found. Two sessions running `/create-brief` against the same
workspace at the same time will compute the same number and one will overwrite
the other, since nothing locks the folder or re-checks after creating it.

Renaming or deleting a numbered folder is also unguarded. Numbers are documented
as never reused, but nothing enforces it, and a plan or report citing
`03--<slug>` will not notice if `03` later means something else.

---

## 9. Plans are not guaranteed to be re-runnable

Nothing in `/create-plans` requires a plan to be safe to run twice. A step that
creates a file will fail, duplicate, or silently overwrite if an abandoned
earlier attempt already produced it.

This matters because the stage 3 repair loop restarts plans from the top by
design. If a session dies mid-plan, the Status cell still reads `pending`, which
is accurate but tells you nothing about how much work already landed.

**Mitigation:** re-read the plan's Preconditions before restarting, and use its
Rollback section to return to the pre-plan state. Plans marked `reversible: no`
have no clean recovery path and must be unwound by hand. See "Resuming after a
partial run" in [handoff.md](handoff.md).

---

## 10. Nothing detects a warm handoff

The pipeline's central guarantee — that plans are self-contained — is only ever
tested at stage 3, and only if the operator opens a genuinely new session.
Executing in the planning conversation produces a *better-looking* run than a
correct handoff would, because the executor silently inherits context the plans
were supposed to carry.

There is no signal for this. Nothing in the artifacts records which model ran a
plan, whether the session was cold, or whether the operator answered questions
in chat. A run that was handed off warm is indistinguishable, after the fact,
from one that was not.
