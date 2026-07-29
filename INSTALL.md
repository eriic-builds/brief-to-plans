# Install

The three skills — `create-brief`, `create-plans`, `dev-report` — are plain
markdown. They become slash commands only when a copy sits where the tool looks
for it.

## Quickest: no clone

The installer works without a checkout. With no `skills/` folder beside it, it
fetches the three `SKILL.md` files over HTTPS and installs nothing else.

**Two steps, so you can read it first:**

```powershell
irm https://raw.githubusercontent.com/eriic-builds/brief-to-plans/main/install.ps1 -OutFile install.ps1
pwsh -File install.ps1 -WhatIf   # drop -WhatIf to apply
```

```bash
curl -fsSLO https://raw.githubusercontent.com/eriic-builds/brief-to-plans/main/install.sh
bash install.sh
```

There is a one-liner — `irm <url> | iex` — and it works, but piping a remote
script straight into your shell means you run whatever that URL serves at that
moment, with your permissions. The two-step version above costs one extra
command and lets you read the script first. Prefer it, and treat the one-liner
as something you use only for a repository you control.

Downloads exactly four files: this script plus three `SKILL.md` files. No
dependencies, no admin rights, no code from the internet is executed.

**Want the reference docs too?** The whole repository is markdown and two
scripts, so a plain clone is already small:

```bash
git clone https://github.com/eriic-builds/brief-to-plans
```

## From a clone

```powershell
pwsh -File install.ps1
```

```bash
./install.sh
```

Then reload the VS Code window and type `/create-brief` in any workspace. With a
local `skills/` folder present the installer never touches the network.

This is the **only** mechanism. The skills are not checked in under `.github/`,
and no `.prompt.md` files are written — both would register the same slash
command a second time. See [Why not both](#why-not-both).

| Command | Effect |
|---|---|
| `pwsh -File install.ps1 -WhatIf` | List every path that would change, write nothing |
| `pwsh -File install.ps1 -Uninstall` | Remove the copies |
| `pwsh -File install.ps1 -Scope repo -RepoRoot <path>` | Install into one repository's `.github/` instead |
| `./install.sh --uninstall` | Same, on macOS and Linux |
| `./install.sh --scope repo --repo-root <path>` | Same, on macOS and Linux |

### Repo scope, if you want it

`-Scope repo` writes `.github/skills/` and `.github/prompts/` into a repository
so the skills travel with a clone and need no install. Useful for handing the
pipeline to a team.

**Pick one scope.** Installing both is what produces duplicate slash commands.
The installer warns when it detects the other scope already present, but it will
not stop you.

## Where each copy lives

| Tool | Location |
|---|---|
| VS Code Copilot Chat **and** the Copilot CLI, all workspaces | `~/.copilot/skills/<name>/SKILL.md` |
| VS Code Copilot Chat **and** the Copilot CLI, one repo (`-Scope repo`) | `<repo>/.github/skills/<name>/SKILL.md` |
| Canonical source | `skills/<name>/SKILL.md` |

**One file per skill, per scope.** Both tools read the same skills folder, so a
single `SKILL.md` serves both. The `.github/` paths are relative to a
**repository root**, not to this folder.

### No `.prompt.md` files

VS Code also supports prompt files — `<name>.prompt.md` in the user prompts
folder or `.github/prompts/` — and an earlier version of this installer wrote
them alongside each `SKILL.md`. That was wrong. Both files register the same
command, so every skill appeared twice from a single scope.

The installer now deletes any prompt file it finds for these three names, so
re-running it repairs an earlier install. If you still see a command listed
twice, check for a stray file:

```powershell
Get-ChildItem "$env:APPDATA\Code\User\prompts" -Filter "*.prompt.md"
```

That folder differs per platform — `~/Library/Application Support/Code/User/prompts`
on macOS, `~/.config/Code/User/prompts` on Linux. The installer clears the
right one for you.

## The canonical copy

`skills/<name>/SKILL.md` is canonical. Every other
copy is generated from it, and the installer reads only from it.

**Editing any one copy does not update the others.** There is no watcher and no
build step. If you change a skill, change the copy under `skills/` first, then
re-run the installer to regenerate the rest. Every installed copy is a verbatim
`SKILL.md`, so a hash comparison is a complete check.

## Why not both

An earlier version of this folder shipped the skills under `.github/` *and*
recommended the installer, *and* wrote a `.prompt.md` next to every `SKILL.md`.
Each of those is a separate registration path, and they are all discovered at
once — so a single skill could appear up to four times. Two registration
channels for one command is a defect, not a convenience.

User scope is the default because it is strictly more useful: it works in every
workspace, which is the whole point of installing. Repo scope remains available
behind `-Scope repo` for anyone who needs clone-and-go, and the files it writes
are regenerated from the canonical copy on demand rather than checked in.

If you see a command listed twice, you have both scopes installed. Remove one:

```powershell
pwsh -File install.ps1 -Scope repo -RepoRoot <path> -Uninstall
```

## No links, no junctions

Do not replace any copy with a symlink, junction or hard link. Junctions have
previously produced duplicate entries in skill listings, and each tool walks
the filesystem differently. Real files in several places is the deliberate
choice; the cost is manual sync.

## Verifying a copy is verbatim

A hash match is the only proof that a copy is untouched. Note `-LiteralPath` —
this repository's path contains square brackets, which PowerShell otherwise
treats as wildcards, silently matching nothing:

```powershell
foreach ($n in @('create-brief','create-plans','dev-report')) {
  $a = (Get-FileHash -LiteralPath "skills\$n\SKILL.md").Hash
  $b = (Get-FileHash -LiteralPath (Join-Path $HOME ".copilot\skills\$n\SKILL.md")).Hash
  "{0}: {1}" -f $n, $(if ($a -eq $b) { 'match' } else { 'MISMATCH' })
}
```

## After installing

Reload the VS Code window, then type `/` in Copilot Chat from any workspace. For
the CLI, start a new session. If a command does not appear, check that the file
is at the path listed in the table above and that its frontmatter parses.
