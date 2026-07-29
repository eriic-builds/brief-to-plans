# Plans index  -  example-cli-tool

Brief: [../BRIEF-example-cli-tool.md](../BRIEF-example-cli-tool.md)

## How to run these

1. Work the plans in the order listed below.
2. Do not start a plan whose `depends_on` row is not yet `done`.
3. When a plan is finished, change its Status cell in this table to `done`.
4. If a step cannot be done exactly as written, stop and report which step and
   why. Do not improvise a substitute.

| # | Plan | Depends on | Status |
|---|---|---|---|
| 1 | [PLAN-scaffold-cli.md](PLAN-scaffold-cli.md) | none | pending |
| 2 | [PLAN-add-config-loader.md](PLAN-add-config-loader.md) | PLAN-scaffold-cli.md | pending |

## Ranked order and leverage rationale

| # | Plan | Leverage | Depends on |
|---|---|---|---|
| 1 | PLAN-scaffold-cli.md | Unblocks everything. Until `scanFolder` returns rows there is nothing for config to filter, and the brief's success signal lives entirely in this plan. | none |
| 2 | PLAN-add-config-loader.md | Additive. Changes three lines of an existing entry point and adds two modules, with a rollback that restores the plan 1 state exactly. | PLAN-scaffold-cli.md |

## Dependency graph

```
PLAN-scaffold-cli.md
  └── PLAN-add-config-loader.md
```

**Start here:** PLAN-scaffold-cli.md  -  it creates the entry point and the
counting core that plan 2 filters, and it alone satisfies the brief's success
signal.
