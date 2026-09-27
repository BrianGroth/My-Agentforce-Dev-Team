<#
.SYNOPSIS
  Validates the six agent files against Descriptions.html and round-trips both install scripts.
  Exit code 0 = all checks pass.
#>
$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
$failures = [System.Collections.Generic.List[string]]::new()
$passes = 0
# $ok may be a bool or a pipeline result; any truthy element counts as a pass.
function Check($ok, [string]$msg) {
    if (@($ok | Where-Object { $_ }).Count -gt 0) { $script:passes++ } else { $script:failures.Add($msg) }
}

$Common = @(
    'Announce yourself',
    'in parallel'
)
$PhaseCommon = @('Installed skills you must use', 'Ground rules', 'Example prompts this agent should handle')

$Spec = [ordered]@{
    orchestrator = @{
        Model = 'opus'; Banner = '🧭 The Orchestrator Agent'
        Tools = 'Agent', 'Read', 'Write', 'Edit', 'Glob', 'Grep', 'Bash'
        Skills = @()
        Sections = 'Why this agent runs on Opus', 'Announce yourself when you work', 'Team roster',
            'How you work: plan, then drive, then self-correct', 'Step 0 — Preflight',
            "The team vs. the plugin's own ADLC agents", 'Bootstrap shared project files', 'Step 1 — Intake',
            'Step 2 — Scaffold first', 'Step 3 — Drive the ADLC loop',
            'Run agents in parallel when work is genuinely independent', 'Step 4 — Escalation and loop-back routes',
            'Loop control & circuit breaker', 'Design Review Gate — human at the helm', 'Deploy model',
            'Deployment handoff — what to tell the user', 'Artifact chain (AI-Native SDLC)',
            'Solution blueprint — you own it', 'Live status panel — you own it', 'Shared logs', 'GitHub convention',
            'Environment constraint — public resources only', 'Fallback — when Agent Teams is not available'
        Mentions = 'SOLUTION-BLUEPRINT.md', 'INCIDENTS.md', 'DECISIONS.md', 'CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS',
            'salesforce-development', 'R1', 'R6', 'same-org invariant'
    }
    architect = @{
        Model = 'sonnet'; Banner = '🏛️ The Architect Agent'
        Tools = 'Read', 'Write', 'Edit', 'Glob', 'Grep', 'Bash', 'Skill', 'Task', 'WebFetch', 'WebSearch'
        Skills = 'salesforce-design', 'salesforce-document'
        Sections = 'Product Requirements Document (PRD) — you own it',
            'RAG / Data 360 — no skill exists, so write explicit instructions',
            'Live org discovery — run at the start of EVERY project',
            'Data 360 & Headless 360 hosted MCP servers — bootstrap check',
            'Agentforce Agent Script DSL — required spec elements',
            'Agentforce Voice — design for the ear from the start',
            'Agentforce Agent Script patterns — apply at spec time', 'Org constraint awareness',
            'Experience Cloud + MIAW design checklist', 'Final solution documentation — co-authored with The QA Agent'
        Mentions = 'platform-environment-validate', 'platform-architecture-analyze', 'platform-metadata-retrieve',
            'platform-sharing-owd-configure', 'platform-sharing-rules-generate', 'agentforce-generate',
            'architecture-review', 'PRD-<solution>.md', 'K.1/K.3/K.4/K.5'
    }
    builder = @{
        Model = 'sonnet'; Banner = '🔨 The Builder Agent'
        Tools = 'Read', 'Write', 'Edit', 'Glob', 'Grep', 'Bash', 'Skill', 'Task'
        Skills = , 'salesforce-develop'
        Sections = 'Plan before you build', 'External Client App for hosted MCP (Data 360 / Headless 360)',
            'Agent Script DSL — hard rules', 'MIAW / Embedded Service Deployment (ESD) — required checks',
            'MIAW widget on an Experience Cloud (Aura) site — embedding approach',
            'ExperienceBundle deploy + publish sequence', 'Agent activation — CLI first, Setup UI as fallback'
        Mentions = 'dx-project-create', 'agentforce-generate', 'platform-apex-generate', 'experience-lwc-generate',
            'platform-custom-object-generate', 'platform-custom-field-generate', 'platform-validation-rule-generate',
            'automation-flow-generate', 'platform-permission-set-generate', 'platform-lsp-integrate',
            'HANDOFF → qa', 'CIRCUIT BREAKER', 'default_agent_user'
    }
    qa = @{
        Model = 'sonnet'; Banner = '✅ The QA Agent'
        Tools = 'Read', 'Write', 'Edit', 'Glob', 'Grep', 'Bash', 'Skill', 'Task'
        Skills = 'salesforce-test', 'salesforce-document'
        Sections = 'Continuous evals (AI-Native SDLC)', 'Agentforce / MIAW validation checklist',
            'Final solution documentation — sections you own'
        Mentions = 'platform-apex-test-run', 'platform-apex-test-generate', 'dx-code-analyzer-run',
            'platform-data-manage', 'agentforce-test', 'Mode C', 'OWASP', '75%', 'K.2', 'CIRCUIT BREAKER'
    }
    shipper = @{
        Model = 'sonnet'; Banner = '🚀 The Shipper Agent'
        Tools = 'Read', 'Write', 'Edit', 'Glob', 'Grep', 'Bash', 'Skill', 'Task'
        Skills = , 'salesforce-release'
        Sections = 'Parallel vs. ordered deploys', 'Tiered autonomy & rollback rehearsal (AI-Native SDLC)',
            'PR, merge, and guided promotion (never auto-deploy on merge)', 'Agentforce release specifics'
        Mentions = 'platform-metadata-deploy', 'platform-deploy-validate', 'platform-quick-deploy',
            'platform-destructive-deploy', 'dx-org-manage', 'platform-manifest-generate', 'sf agent publish',
            'sf agent activate', 'HANDOFF → sentinel', 'BotVersion'
    }
    sentinel = @{
        Model = 'sonnet'; Banner = '🛰️ The Sentinel Agent'
        Tools = 'Read', 'Write', 'Edit', 'Glob', 'Grep', 'Bash', 'WebFetch', 'Skill', 'Task'
        Skills = , 'salesforce-observe'
        Sections = 'Control-band monitoring (AI-Native SDLC)', 'MIAW live-site health checks'
        Mentions = 'platform-apex-logs-debug', 'agentforce-observe', 'agentforce-test', 'Mode C',
            'PRIORITY: ROLLBACK', 'INCIDENTS.md', 'phase 10'
    }
}

foreach ($name in $Spec.Keys) {
    $s = $Spec[$name]
    $path = Join-Path $Root "agents/$name.md"
    Check (Test-Path $path) "${name}: file agents/$name.md missing"
    if (-not (Test-Path $path)) { continue }
    $text = Get-Content -LiteralPath $path -Raw -Encoding utf8

    # Frontmatter
    $m = [regex]::Match($text, '(?s)\A---\r?\n(.*?)\r?\n---\r?\n')
    Check $m.Success "${name}: missing YAML frontmatter"
    $fm = $m.Groups[1].Value
    Check ($fm -match "(?m)^name:\s*$name\s*$") "${name}: frontmatter name must be '$name'"
    Check ($fm -match "(?m)^description:\s*\S") "${name}: frontmatter description missing"
    Check ($fm -match "(?m)^model:\s*$($s.Model)\s*$") "${name}: model must be $($s.Model)"
    Check ($fm -match '(?m)^memory:\s*project\s*$') "${name}: memory: project missing"
    $toolsLine = [regex]::Match($fm, '(?m)^tools:\s*(.+)$').Groups[1].Value
    $tools = $toolsLine -split ',\s*' | ForEach-Object { $_.Trim() }
    foreach ($t in $s.Tools) { Check ($tools -contains $t) "${name}: tools missing '$t'" }
    $skillBlock = [regex]::Match($fm, '(?ms)^skills:\s*\r?\n((?:\s+-\s*.+\r?\n?)+)').Groups[1].Value
    $skills = [regex]::Matches($skillBlock, '-\s*(\S+)') | ForEach-Object { $_.Groups[1].Value }
    if ($s.Skills.Count -eq 0) { Check (-not ($fm -match '(?m)^skills:')) "${name}: orchestrator must have no skills" }
    foreach ($k in $s.Skills) { Check ($skills -contains $k) "${name}: preloaded skill '$k' missing" }

    # Headings
    $headings = [regex]::Matches($text, '(?m)^#{2,3}\s+(.+?)\s*$') | ForEach-Object { $_.Groups[1].Value }
    Check ($headings | Where-Object { $_ -like 'Announce yourself*' }) "${name}: missing 'Announce yourself…' section"
    Check ($headings | Where-Object { $_ -match '^Run .+ in parallel' }) "${name}: missing 'Run … in parallel' section"
    if ($name -ne 'orchestrator') {
        foreach ($h in $PhaseCommon) { Check ($headings -contains $h) "${name}: missing common section '$h'" }
        Check ($headings | Where-Object { $_ -like 'Hand-off*' }) "${name}: missing hand-off/escalation section"
    } else {
        foreach ($h in $PhaseCommon) { Check (-not ($headings -contains $h)) "orchestrator: must not have '$h' section" }
    }
    foreach ($h in $s.Sections) { Check ($headings -contains $h) "${name}: missing section '$h'" }

    # Banner + key mentions
    Check ($text.Contains("**$($s.Banner)**")) "${name}: banner '**$($s.Banner)**' missing"
    foreach ($w in $s.Mentions) { Check ($text.Contains($w)) "${name}: should mention '$w'" }
}

# Orchestrator ADLC table has 12 phases
$orch = Get-Content -LiteralPath (Join-Path $Root 'agents/orchestrator.md') -Raw -Encoding utf8
foreach ($i in 1..12) { Check ($orch -match "(?m)^\|\s*$i\s*\|") "orchestrator: ADLC table missing phase $i" }
foreach ($r in 'R1 Circuit breaker', 'R2 Design gap', 'R3 Code bug', 'R4 Untested surface', 'R5 Production issue', 'R6 Rollback') {
    Check ($orch.Contains($r)) "orchestrator: escalation route '$r' missing"
}

# Templates
foreach ($t in 'INCIDENTS.md', 'DECISIONS.md', 'SOLUTION-BLUEPRINT.md', 'PRD-template.md', 'SOLUTION-DOC-template.md', 'CLAUDE.md.snippet') {
    Check (Test-Path (Join-Path $Root "templates/$t")) "template $t missing"
}
$doc = Get-Content -LiteralPath (Join-Path $Root 'templates/SOLUTION-DOC-template.md') -Raw -Encoding utf8
foreach ($sec in 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J') { Check ($doc -match "(?m)^## $sec\. ") "SOLUTION-DOC: section $sec missing" }
foreach ($sec in 'K.1', 'K.2', 'K.3', 'K.4', 'K.5') { Check ($doc -match "(?m)^### $([regex]::Escape($sec)) ") "SOLUTION-DOC: section $sec missing" }
$bp = Get-Content -LiteralPath (Join-Path $Root 'templates/SOLUTION-BLUEPRINT.md') -Raw -Encoding utf8
foreach ($sec in '## 1. Header', '## 2. Architecture diagram', '## 3. Component inventory', '## 4. Manual org-config steps', '## 5. Rebuild-in-a-new-org checklist', '## Rollback path') {
    Check ($bp.Contains($sec)) "SOLUTION-BLUEPRINT: '$sec' missing"
}

# Install round-trip for both scripts
function Test-Install([string]$label, [scriptblock]$install, [scriptblock]$uninstall) {
    $dir = Join-Path ([IO.Path]::GetTempPath()) ("mdt-test-" + [guid]::NewGuid().ToString('N').Substring(0, 8))
    New-Item -ItemType Directory -Path $dir | Out-Null
    try {
        Set-Content -LiteralPath (Join-Path $dir 'CLAUDE.md') -Value "# Existing project notes`n`nKeep me.`n" -NoNewline
        & $install $dir | Out-Null
        & $install $dir | Out-Null   # idempotent update
        foreach ($a in 'orchestrator', 'architect', 'builder', 'qa', 'shipper', 'sentinel') {
            $dst = Join-Path $dir ".claude/agents/$a.md"
            Check ((Test-Path $dst) -and ((Get-FileHash $dst).Hash -eq (Get-FileHash (Join-Path $Root "agents/$a.md")).Hash)) "${label}: $a.md not installed identically"
        }
        Check (Test-Path (Join-Path $dir '.claude/my-dev-team/templates/PRD-template.md')) "${label}: templates not installed"
        $cm = Get-Content -LiteralPath (Join-Path $dir 'CLAUDE.md') -Raw
        Check (([regex]::Matches($cm, 'BEGIN MY-DEV-TEAM')).Count -eq 1) "${label}: CLAUDE.md block count != 1 after two installs"
        Check ($cm.Contains('Keep me.')) "${label}: existing CLAUDE.md content lost"
        Check (@(Get-ChildItem (Join-Path $dir '.claude/agents') -Filter '*.bak-*').Count -eq 0) "${label}: unexpected backups on identical re-install"

        # Local modification is backed up on update
        Add-Content -LiteralPath (Join-Path $dir '.claude/agents/qa.md') -Value 'local tweak'
        & $install $dir | Out-Null
        Check (@(Get-ChildItem (Join-Path $dir '.claude/agents') -Filter 'qa.md.bak-*').Count -eq 1) "${label}: modified agent not backed up"

        & $uninstall $dir | Out-Null
        Check (-not (Test-Path (Join-Path $dir '.claude/agents/orchestrator.md'))) "${label}: uninstall left agents"
        Check (-not (Test-Path (Join-Path $dir '.claude/my-dev-team'))) "${label}: uninstall left templates"
        $cm = Get-Content -LiteralPath (Join-Path $dir 'CLAUDE.md') -Raw
        Check ((-not $cm.Contains('MY-DEV-TEAM')) -and $cm.Contains('Keep me.')) "${label}: uninstall did not cleanly remove CLAUDE.md block"
    } finally {
        Remove-Item -LiteralPath $dir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Test-Install 'install.ps1' { param($d) & (Join-Path $Root 'install.ps1') -Target $d 6>$null } { param($d) & (Join-Path $Root 'install.ps1') -Target $d -Uninstall 6>$null }

$bash = (Get-Command bash -ErrorAction SilentlyContinue).Source
if (-not $bash -and (Test-Path "$env:ProgramFiles\Git\bin\bash.exe")) { $bash = "$env:ProgramFiles\Git\bin\bash.exe" }
if ($bash) {
    function ConvertTo-BashPath([string]$p) {
        $full = [IO.Path]::GetFullPath($p)
        if ($IsWindows -or $env:OS -eq 'Windows_NT') { return '/' + $full.Substring(0, 1).ToLower() + ($full.Substring(2) -replace '\\', '/') }
        return $full
    }
    $sh = ConvertTo-BashPath (Join-Path $Root 'install.sh')
    Test-Install 'install.sh' { param($d) & $bash $sh (ConvertTo-BashPath $d); if ($LASTEXITCODE) { throw "install.sh failed" } } { param($d) & $bash $sh (ConvertTo-BashPath $d) --uninstall; if ($LASTEXITCODE) { throw "install.sh --uninstall failed" } }
} else {
    Write-Warning 'bash not found — skipped install.sh round-trip'
}

Write-Host "`n$passes checks passed, $($failures.Count) failed."
if ($failures.Count) { $failures | ForEach-Object { Write-Host "  FAIL: $_" -ForegroundColor Red }; exit 1 }
Write-Host 'All checks passed.' -ForegroundColor Green
