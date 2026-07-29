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
