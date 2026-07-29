---
name: "dev-report"
description: "Stage 4 of the brief-to-plans pipeline. Analyze an executed codebase and produce one self-contained interactive HTML page that teaches how it works: summary, architecture diagram, execution flow, component explorer, dependency tree, design decisions, code walkthrough, lessons, FAQ. Reads the BRIEF and Plans to explain intent and flag plan-vs-reality drift. Use when Eric says \"dev report\", \"/dev-report\", \"explain this codebase\", or \"what did the AI actually do\"."
---

# /dev-report  -  Teach me what got built

Produce one self-contained `DEV-REPORT-<slug>.html` that explains a codebase to someone who has never seen it.

## Project folder resolution  -  authoritative

**This section overrides every other folder instruction in this file.**

Runs live in numbered project folders inside `dev-docs/` at the workspace root:

```
<workspace root>/
└── dev-docs/
    ├── 01--<slug>/
    │   ├── BRIEF-<slug>.md
    │   ├── Plans/
    │   └── DEV-REPORT-<slug>.html    you write this
    └── NN--<slug>/
```

**Find the project folder, in this order:**

1. If Eric pointed at a project folder, use that.
2. Otherwise glob `<workspace root>/dev-docs/*/BRIEF-*.md` and use the folder
   containing the match. If several match, list them and ask.
3. Otherwise look for `BRIEF-*.md` in the folder the session is running in.
4. If no brief exists anywhere, run standalone and write the report to
   `<workspace root>/dev-docs/<NN>--<slug>/`, creating `dev-docs/` and the next
   numbered folder if needed.

**The code you are documenting lives in the workspace root, not under
`dev-docs/`.** Read the code from the workspace; write the report into the
project folder. Never document `dev-docs/` itself as if it were the codebase.

## Where this sits

Stage 1 `/create-brief` → stage 2 `/create-plans` → stage 3 executor model builds it → **stage 4 you** explain it.

```
<project folder>/
├── BRIEF-<slug>.md            the why
├── Plans/                     the intended how
└── DEV-REPORT-<slug>.html     you write this
```

## Why this beats a generic code explainer

You have the brief and the plans. That means you can explain **intent**, not just mechanics, and you can see where reality diverged from the plan. A normal code walkthrough cannot do either. Lean on that advantage.

## Step 1  -  Read three things, in this order

**Find the project folder first**, using "Project folder resolution" above: a folder Eric pointed at, else a `dev-docs/<NN>--<slug>/` folder holding a `BRIEF-*.md`, else the folder the session is running in.

1. **`BRIEF-*.md`** - the goal, constraints, non-goals. This is the source of "why it exists".
2. **`Plans/` + `PLANS-INDEX.md`** - the intended approach, recorded edge cases, and which plans are marked `done`. This is the source of "the reasoning behind technical decisions".
3. **The actual code** - the ground truth.

If no brief or plans exist, run standalone: analyze the codebase, skip the drift section, and say in chat that design rationale is inferred rather than recorded.

## Who this is for

Eric reads this to **see how the run went and to learn what the AI actually did** — not to sign off on it. It is a teaching artifact and a retrospective, not a validation gate. So favour explanation over assurance: show the reasoning, show where things went sideways, and never imply the code is verified correct just because the report reads cleanly.

## Step 2  -  Ground everything in the code

**The code is the truth, not the plans.** Plans describe what was supposed to happen. Read every file you document. Never describe a function, file, or flow you have not opened.

Where the implementation and the plan disagree, that is a finding, not an error to smooth over. Capture it.

## Step 3  -  Build the page

Invoke `/web-artifacts-builder` for the HTML shell and the Clawpilot theme. Project folders sit under OneDrive, so **follow its sandbox-safe rules** - these reports get opened through OneDrive and SharePoint in-browser preview.

Hard constraint: **fully self-contained.** Inline CSS, inline JS, no CDN, no external fonts, no build step. That rules out CDN-loaded diagram libraries - **draw diagrams as inline SVG.**

### Required sections

| Section | Contains |
|---|---|
| Executive Summary | What this is, what it does, who it is for. Readable in 60 seconds. |
| Architecture Diagram | Inline SVG. Boxes are real components, arrows are real calls. |
| Execution Flow Timeline | What happens in what order when the thing runs. |
| Component Explorer | One expandable card per component, using the seven fields below. |
| File Dependency Tree | What imports what. Collapsible. |
| Key Design Decisions | Decision, why, alternatives rejected, sourced from brief and plans. |
| Code Walkthrough | The handful of passages that matter, annotated line by line. |
| Plan vs Reality | Where execution diverged from the plans, and why it likely happened. Omit when standalone. |
| Lessons Learned | What a reader should carry to the next project. |
| FAQ | The questions a newcomer actually asks on day one. |

### Seven fields per component

1. What it does
2. Why it exists
3. How it interacts with other components
4. Key files involved (real paths, verified)
5. Important functions and classes (real names, verified)
6. Tradeoffs and alternatives
7. Learning moments and best practices

### Interactive features

- Expand and collapse on every major section and component card
- Search box filtering visible content live
- Filter chips by component
- Complexity indicator per component, colour coded, with the rating criteria stated so the colours are not arbitrary
- Tooltips on technical terms, defined in plain language

All of it in vanilla JS. Search and filters must work from `file://` with no server.

## Teaching style

ELI5 first, technical second, always in that order. Give the plain-language version and the real-world analogy before any jargon appears.

Eric reads better with short lines, clear hierarchy, and generous spacing. Favour short paragraphs and visible structure over dense prose. Never introduce a term in the ELI5 layer that only the technical layer defines.

Analogies must be load-bearing and accurate. A wrong analogy is worse than none, because it teaches a confident misunderstanding that has to be unlearned later.

## Step 4  -  Write and verify

Write `DEV-REPORT-<slug>.html` to the **project folder root**. Take the slug from the brief's `slug:` field; if it has none, derive it from the brief's filename, and if there is no brief, from the project folder name.

Before delivering, open it and check:

1. Does it render with no console errors?
2. Do search, filters, and every expand and collapse actually work?
3. Are all diagrams inline SVG, with zero external requests?
4. Is every file path and function name real?
5. Could someone who has never seen this repo follow the execution flow start to finish?

Fix anything that fails before reporting.

## Report to chat

The path written, one line on what the report covers, and the drift findings if any - those are the part Eric most needs to see and the part he cannot get anywhere else. No closing offer to refine.

## What NOT to do

- Do not describe code you have not opened
- Do not document what the plans said instead of what the code does
- Do not hide or soften plan-to-reality drift
- Do not use a CDN, external font, or external diagram library
- Do not invent design rationale when the brief and plans already record it
- Do not lead with jargon before the plain-language explanation
- Do not ship a colour-coded complexity rating without stating the criteria
- Do not produce a report that needs a server to work
