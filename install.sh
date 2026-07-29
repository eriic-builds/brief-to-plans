#!/usr/bin/env bash
# Installs the brief-to-plans skills so /create-brief, /create-plans and
# /dev-report appear in VS Code Copilot Chat and the Copilot CLI.
#
#   ./install.sh                       install at user scope, every workspace
#   ./install.sh --scope repo          install into one repo's .github/ instead
#   ./install.sh --scope repo --repo-root .
#   ./install.sh --uninstall           remove the copies for that scope
#
# With no local checkout, the three SKILL.md files are fetched over HTTPS from
# the repository instead - nothing else is downloaded and nothing is executed.
#
# One SKILL.md per skill is all that is needed - both tools read the same
# skills folder. Writing a matching .prompt.md as well registers the command
# twice. Uninstall still clears those, to clean up earlier installs.

set -euo pipefail

names=(create-brief create-plans dev-report)
raw_base="https://raw.githubusercontent.com/eriic-builds/brief-to-plans/main/skills"

if [ -n "${BASH_SOURCE[0]:-}" ] && [ -f "${BASH_SOURCE[0]}" ]; then
  here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  source_dir="$here/skills"
else
  source_dir=""
fi

if [ -n "$source_dir" ] && [ -d "$source_dir" ]; then from_web=0; else from_web=1; fi

scope=user
repo_root="$PWD"
uninstall=0

while [ $# -gt 0 ]; do
  case "$1" in
    --scope)     scope="${2:-}"; shift 2 ;;
    --repo-root) repo_root="${2:-}"; shift 2 ;;
    --uninstall) uninstall=1; shift ;;
    *) echo "Unknown argument: $1" >&2; exit 1 ;;
  esac
done

case "$scope" in user|repo) ;; *) echo "--scope must be user or repo" >&2; exit 1 ;; esac
[ -d "$repo_root" ] || { echo "No such folder: $repo_root" >&2; exit 1; }

if [ "$scope" = user ]; then
  skill_root="$HOME/.copilot/skills"
  # Only used to clear prompt files left by earlier versions of this script.
  case "$(uname -s)" in
    Darwin) legacy_prompt_root="$HOME/Library/Application Support/Code/User/prompts" ;;
    *)      legacy_prompt_root="${XDG_CONFIG_HOME:-$HOME/.config}/Code/User/prompts" ;;
  esac
  other_skill_root="$repo_root/.github/skills"
else
  skill_root="$repo_root/.github/skills"
  legacy_prompt_root="$repo_root/.github/prompts"
  other_skill_root="$HOME/.copilot/skills"
fi

if [ "$uninstall" = 1 ]; then
  for n in "${names[@]}"; do
    rm -rf "$skill_root/$n"                   && echo "removed  $skill_root/$n"
    rm -f  "$legacy_prompt_root/$n.prompt.md" && echo "removed  $legacy_prompt_root/$n.prompt.md"
  done
  echo; echo "Done. Reload the VS Code window."
  exit 0
fi

# Duplicate slash commands are the one thing two scopes reliably cause.
for n in "${names[@]}"; do
  if [ -d "$other_skill_root/$n" ]; then
    echo "warning: also installed at the other scope: $other_skill_root/$n" >&2
    echo "warning: two scopes means duplicate slash commands. Uninstall one." >&2
    break
  fi
done

for n in "${names[@]}"; do
  mkdir -p "$skill_root/$n"

  if [ "$from_web" = 1 ]; then
    curl -fsSL "$raw_base/$n/SKILL.md" -o "$skill_root/$n/SKILL.md"
    grep -q '^description:' "$skill_root/$n/SKILL.md" || {
      echo "Downloaded $n/SKILL.md does not look like a skill." >&2; exit 1; }
  else
    src="$source_dir/$n/SKILL.md"
    [ -f "$src" ] || { echo "Missing source skill: $src" >&2; exit 1; }
    cp "$src" "$skill_root/$n/SKILL.md"
  fi
  echo "skill    $skill_root/$n/SKILL.md"

  # A leftover prompt file from an earlier install registers a second copy.
  if [ -f "$legacy_prompt_root/$n.prompt.md" ]; then
    rm -f "$legacy_prompt_root/$n.prompt.md"
    echo "removed  $legacy_prompt_root/$n.prompt.md  (would have duplicated the command)"
  fi
done

echo
echo "Installed ${#names[@]} skills at $scope scope."
echo "Reload the VS Code window, then type /create-brief."
