<#
.SYNOPSIS
  Installs (or updates / uninstalls) My Dev Team into a local Agentforce project folder.

.DESCRIPTION
  Copies the six agents into <Target>/.claude/agents/, the templates into
  <Target>/.claude/my-dev-team/templates/, and adds a managed routing block to
  <Target>/CLAUDE.md so "My Dev Team" runs the orchestrator in the main thread.
  Re-running updates the team in place; locally modified agent files are backed up first.
  Never touches project files such as INCIDENTS.md, DECISIONS.md, PRDs, or source.

.EXAMPLE
  ./install.ps1 -Target C:\dev\my-agentforce-project
.EXAMPLE
  ./install.ps1 -Target C:\dev\my-agentforce-project -Uninstall
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Target,
    [switch]$Uninstall
)

$ErrorActionPreference = 'Stop'
$Source = $PSScriptRoot
$Agents = 'orchestrator', 'architect', 'builder', 'qa', 'shipper', 'sentinel'
$BeginMarker = '<!-- BEGIN MY-DEV-TEAM'
$EndMarker = '<!-- END MY-DEV-TEAM -->'

if (-not (Test-Path -LiteralPath $Target -PathType Container)) {
    throw "Target folder not found: $Target"
}
$Target = (Resolve-Path -LiteralPath $Target).Path
if ($Target -eq $Source) { throw 'Target must be a project folder, not the My-Agentforce-Dev-Team repo itself.' }

$AgentsDir = Join-Path $Target '.claude/agents'
$TeamDir = Join-Path $Target '.claude/my-dev-team'
$ClaudeMd = Join-Path $Target 'CLAUDE.md'

function Remove-ManagedBlock([string]$text) {
    $pattern = '(?s)\r?\n?' + [regex]::Escape($BeginMarker) + '.*?' + [regex]::Escape($EndMarker) + '\r?\n?'
    return [regex]::Replace($text, $pattern, "`n")
}

if ($Uninstall) {
    foreach ($a in $Agents) {
        $f = Join-Path $AgentsDir "$a.md"
        if (Test-Path -LiteralPath $f) { Remove-Item -LiteralPath $f; Write-Host "removed  .claude/agents/$a.md" }
    }
    if (Test-Path -LiteralPath $TeamDir) { Remove-Item -LiteralPath $TeamDir -Recurse; Write-Host 'removed  .claude/my-dev-team/' }
    if (Test-Path -LiteralPath $ClaudeMd) {
        $text = Get-Content -LiteralPath $ClaudeMd -Raw
        if ($text.Contains($BeginMarker)) {
            $new = (Remove-ManagedBlock $text).Trim()
            if ($new) { Set-Content -LiteralPath $ClaudeMd -Value ($new + "`n") -NoNewline } else { Remove-Item -LiteralPath $ClaudeMd }
            Write-Host 'removed  My Dev Team block from CLAUDE.md'
        }
    }
    Write-Host "`nMy Dev Team uninstalled from $Target. Project logs (INCIDENTS.md, DECISIONS.md, SOLUTION-BLUEPRINT.md, PRDs) were left in place."
    return
}

New-Item -ItemType Directory -Force -Path $AgentsDir, (Join-Path $TeamDir 'templates') | Out-Null
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'

# Agents: overwrite, backing up any locally modified copy first.
foreach ($a in $Agents) {
    $src = Join-Path $Source "agents/$a.md"
    $dst = Join-Path $AgentsDir "$a.md"
    if (Test-Path -LiteralPath $dst) {
        if ((Get-FileHash -LiteralPath $src).Hash -eq (Get-FileHash -LiteralPath $dst).Hash) {
            Write-Host "same     .claude/agents/$a.md"; continue
        }
        Copy-Item -LiteralPath $dst -Destination "$dst.bak-$stamp"
        Write-Host "backup   .claude/agents/$a.md -> $a.md.bak-$stamp"
    }
    Copy-Item -LiteralPath $src -Destination $dst -Force
    Write-Host "install  .claude/agents/$a.md"
}

# Templates: team-owned, always refreshed.
Copy-Item -Path (Join-Path $Source 'templates/*') -Destination (Join-Path $TeamDir 'templates') -Recurse -Force
Write-Host 'install  .claude/my-dev-team/templates/'

$version = 'unknown'
try { $version = (git -C $Source rev-parse --short HEAD 2>$null) } catch { }
Set-Content -LiteralPath (Join-Path $TeamDir 'VERSION') -Value "My-Agentforce-Dev-Team $version installed $(Get-Date -Format s)"

# CLAUDE.md managed routing block.
$snippet = (Get-Content -LiteralPath (Join-Path $Source 'templates/CLAUDE.md.snippet') -Raw).Trim()
if (Test-Path -LiteralPath $ClaudeMd) {
    $text = Get-Content -LiteralPath $ClaudeMd -Raw
    if ($text.Contains($BeginMarker)) {
        $text = (Remove-ManagedBlock $text).TrimEnd()
        Write-Host 'update   CLAUDE.md (My Dev Team block)'
    } else {
        $text = $text.TrimEnd()
        Write-Host 'append   CLAUDE.md (My Dev Team block)'
    }
    $out = if ($text) { "$text`n`n$snippet`n" } else { "$snippet`n" }
} else {
    $out = "$snippet`n"
    Write-Host 'create   CLAUDE.md'
}
Set-Content -LiteralPath $ClaudeMd -Value $out -NoNewline

Write-Host @"

My Dev Team ($version) installed into $Target

Before first use, install these Claude Code plugins/skills (see README):
  - salesforce-development, salesforce-code-quality, experience-lwc  (forcedotcom/sf-skills)
  - agentforce-adlc                                                  (SalesforceAIResearch/agentforce-adlc)
  - phase skills: salesforce-design, salesforce-develop, salesforce-test,
                  salesforce-release, salesforce-observe, salesforce-document

Then open Claude Code in that folder and say:  My Dev Team, build <what you need>
"@
