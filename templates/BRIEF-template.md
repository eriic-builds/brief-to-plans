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
