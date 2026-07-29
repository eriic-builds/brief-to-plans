#!/usr/bin/env pwsh
# Installs the brief-to-plans skills so /create-brief, /create-plans and
# /dev-report appear in VS Code Copilot Chat and the Copilot CLI.
#
#   pwsh -File install.ps1                  install at user scope, every workspace
#   pwsh -File install.ps1 -Scope repo      install into one repo's .github/ instead
#   pwsh -File install.ps1 -WhatIf          show what would change, write nothing
#   pwsh -File install.ps1 -Uninstall       remove the copies for that scope
#
# With no local checkout, the three SKILL.md files are fetched over HTTPS from
# the repository instead — nothing else is downloaded and nothing is executed.
#
# One SKILL.md per skill is all that is needed — both tools read the same
# skills folder. Writing a matching .prompt.md as well registers the command
# twice. Uninstall still clears those, to clean up earlier installs.

[CmdletBinding(SupportsShouldProcess)]
param(
    [ValidateSet('user', 'repo')]
    [string]$Scope = 'user',

    [string]$RepoRoot = $PWD,

    [switch]$Uninstall
)

$ErrorActionPreference = 'Stop'

$names   = @('create-brief', 'create-plans', 'dev-report')
$rawBase = 'https://raw.githubusercontent.com/eriic-builds/brief-to-plans/main/skills'

# $PSScriptRoot is empty when the script is piped straight into the shell.
$source  = if ($PSScriptRoot) { Join-Path $PSScriptRoot 'skills' } else { $null }
$fromWeb = -not ($source -and (Test-Path -LiteralPath $source))

if (-not (Test-Path -LiteralPath $RepoRoot)) { throw "No such folder: $RepoRoot" }
$repoPath = (Resolve-Path -LiteralPath $RepoRoot).Path

if ($Scope -eq 'user') {
    $skillRoot = Join-Path $HOME '.copilot/skills'

    # Only used to clear prompt files left by earlier versions of this script.
    $legacyPromptRoot = if ($IsMacOS) {
        Join-Path $HOME 'Library/Application Support/Code/User/prompts'
    } elseif ($IsLinux) {
        Join-Path $HOME '.config/Code/User/prompts'
    } else {
        Join-Path $env:APPDATA 'Code/User/prompts'
    }
} else {
    $skillRoot        = Join-Path $repoPath '.github/skills'
    $legacyPromptRoot = Join-Path $repoPath '.github/prompts'
}

if ($Uninstall) {
    foreach ($n in $names) {
        $skillDir = Join-Path $skillRoot $n
        $prompt   = Join-Path $legacyPromptRoot "$n.prompt.md"
        if (Test-Path -LiteralPath $skillDir) {
            if ($PSCmdlet.ShouldProcess($skillDir, 'Remove')) { Remove-Item -LiteralPath $skillDir -Recurse -Force }
            Write-Host "removed  $skillDir"
        }
        if (Test-Path -LiteralPath $prompt) {
            if ($PSCmdlet.ShouldProcess($prompt, 'Remove')) { Remove-Item -LiteralPath $prompt -Force }
            Write-Host "removed  $prompt  (legacy prompt file)"
        }
    }
    Write-Host "`nDone. Reload the VS Code window."
    return
}

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

# Duplicate slash commands are the one thing two scopes reliably cause.
$otherSkillRoot = if ($Scope -eq 'user') { Join-Path $repoPath '.github/skills' }
                  else { Join-Path $HOME '.copilot/skills' }
$clashes = $names | Where-Object { Test-Path -LiteralPath (Join-Path $otherSkillRoot $_) }
if ($clashes) {
    Write-Warning "Also installed at the other scope: $($clashes -join ', ')"
    Write-Warning "in $otherSkillRoot"
    Write-Warning "Two scopes means duplicate slash commands. Uninstall one of them."
}

foreach ($n in $names) {
    if ($fromWeb) {
        $text = (Invoke-WebRequest -Uri "$rawBase/$n/SKILL.md" -UseBasicParsing).Content
        if ($text -notmatch '(?m)^description:') { throw "Downloaded $n/SKILL.md does not look like a skill." }
    } else {
        $src = Join-Path $source "$n/SKILL.md"
        if (-not (Test-Path -LiteralPath $src)) { throw "Missing source skill: $src" }
        $text = [System.IO.File]::ReadAllText($src)
    }

    $skillDir  = Join-Path $skillRoot $n
    $skillDest = Join-Path $skillDir 'SKILL.md'
    if ($PSCmdlet.ShouldProcess($skillDest, 'Install skill')) {
        New-Item -ItemType Directory -Force -Path $skillDir | Out-Null
        [System.IO.File]::WriteAllText($skillDest, $text, $utf8NoBom)
    }
    Write-Host "skill    $skillDest"

    # A leftover prompt file from an earlier install registers a second copy.
    $stale = Join-Path $legacyPromptRoot "$n.prompt.md"
    if (Test-Path -LiteralPath $stale) {
        if ($PSCmdlet.ShouldProcess($stale, 'Remove duplicate prompt file')) { Remove-Item -LiteralPath $stale -Force }
        Write-Host "removed  $stale  (would have duplicated the command)"
    }
}

Write-Host "`nInstalled $($names.Count) skills at $Scope scope$(if ($fromWeb) { ' (fetched over HTTPS)' })."
Write-Host "Reload the VS Code window, then type /create-brief."
