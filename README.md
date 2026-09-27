# My-Agentforce-Dev-Team

A 6-agent **Claude Code** team covering the full Salesforce / Agentforce Development Lifecycle (ADLC), from design through production monitoring. Install it into any local Agentforce project folder, then say **"My Dev Team, build X"**. The Orchestrator Agent takes the lead, works with you, and coordinates the other five agents through gated phases.

Full design reference: [`Descriptions.html`](Descriptions.html).

| | Agent | Routing name | Phase | Model | Preloaded skill(s) |
|---|---|---|---|---|---|
| 🧭 | The Orchestrator Agent | `orchestrator` | Coordination, gates, circuit breaker, blueprint | Opus | — |
| 🏛️ | The Architect Agent | `architect` | Ideation & Design → `PRD-<solution>.md` | Sonnet | `salesforce-design`, `salesforce-document` |
| 🔨 | The Builder Agent | `builder` | Development → LSP-clean metadata on the feature branch | Sonnet | `salesforce-develop` |
| ✅ | The QA Agent | `qa` | Testing & Validation → sign-off (coverage, evals, OWASP grade) | Sonnet | `salesforce-test`, `salesforce-document` |
| 🚀 | The Shipper Agent | `shipper` | Deployment & Release → validated deploy, Active BotVersion, rollback path | Sonnet | `salesforce-release` |
| 🛰️ | The Sentinel Agent | `sentinel` | Monitoring & Tuning → verification record or routed incident | Sonnet | `salesforce-observe` |

## Repository layout

```
agents/                 the six agent definitions (Claude Code subagent format)
templates/              PRD, SOLUTION-BLUEPRINT, SOLUTION-DOC, INCIDENTS, DECISIONS, CLAUDE.md routing block
install.ps1             copy-in installer for Windows / PowerShell
install.sh              copy-in installer for macOS / Linux / Git Bash
tests/validate.ps1      checks every agent against the spec and round-trips both installers
Descriptions.html       the team specification
```

## Prerequisites

Install these **before** running the team. The agents call these skills and do not fall back to improvised CLI commands.

1. **Claude Code**, **Salesforce CLI** (`sf`), **git**, and the **GitHub CLI** (`gh auth login`).
2. Claude Code plugins:
   - `salesforce-development`, `salesforce-code-quality`, `experience-lwc` from [forcedotcom/sf-skills](https://github.com/forcedotcom/sf-skills)
   - `agentforce-adlc` from [SalesforceAIResearch/agentforce-adlc](https://github.com/SalesforceAIResearch/agentforce-adlc)
3. The six team phase skills: `salesforce-design`, `salesforce-develop`, `salesforce-test`, `salesforce-release`, `salesforce-observe`, `salesforce-document`. They can be installed at the user level (`~/.claude/skills/`) or in the project (`.claude/skills/`).

The orchestrator's **Step 0 Preflight** checks all of these and tells you what's missing.

## Install into a project folder

Clone this repo once, then copy the team into each Agentforce project:

```powershell
git clone https://github.com/BrianGroth/My-Agentforce-Dev-Team.git
./My-Agentforce-Dev-Team/install.ps1 -Target C:\dev\my-agentforce-project
```

```bash
./My-Agentforce-Dev-Team/install.sh ~/dev/my-agentforce-project
```

The installer:
- copies the six agents to `<project>/.claude/agents/`
- copies the templates to `<project>/.claude/my-dev-team/templates/` and writes a `VERSION` file
- adds a managed block to `<project>/CLAUDE.md` so "My Dev Team" routes to the orchestrator. Existing CLAUDE.md content is kept.

**Update:** run `git pull` in this repo, then re-run the installer. If an agent was edited locally, the installer backs it up as `<agent>.md.bak-<timestamp>` before overwriting it.
**Uninstall:** add `-Uninstall` (PowerShell) or `--uninstall` (bash). Project files (`INCIDENTS.md`, `DECISIONS.md`, `SOLUTION-BLUEPRINT.md`, PRDs, source) are never touched.

Each project gets its own copy, so you can tailor one project's agents without affecting the others.

## Use

Open Claude Code in the project folder and say:

> My Dev Team, build a service agent that answers order-status questions on our web chat, in the `uat` sandbox.

The orchestrator runs preflight and collects the six intake answers: project name, target org, RAG status, GitHub repo, channel, and whether DX scaffolding is needed. It then drives the 12-phase loop and prints a live status panel at every transition. You act at two gates:

1. **Design Review Gate:** approve the PRD before any build starts.
2. **Production Gate:** approve the validated deploy before production is touched.

Shipper opens the PR, and **you merge it**. Merging never deploys anything; promotion is a separate, guided step.

For single-phase work, name the agent directly, e.g. *"qa, re-run the eval set against uat"* or *"sentinel, check production logs for the order agent"*.

### Why the orchestrator runs in the main thread

Claude Code subagents cannot spawn other subagents. The CLAUDE.md block therefore has the **main conversation** act as the orchestrator, instead of spawning it as a subagent. You can also start a session with `claude --agent orchestrator`.

Phase agents describe some direct handoffs (builder → qa, shipper → sentinel, sentinel → shipper rollback). How these run depends on the mode:
- **Agent Teams mode** (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`): teammates message each other directly with `SendMessage`.
- **Default mode:** the phase agent ends its result with a `HANDOFF → <agent>` block, and the orchestrator runs it unchanged. A `PRIORITY: ROLLBACK` handoff jumps the queue.

## Files the team creates in your project

| File | Owner |
|---|---|
| `SOLUTION-BLUEPRINT.md` | orchestrator: component map, manual org steps, rebuild checklist, loop state, rollback path |
| `PRD-<solution>.md` | architect |
| `BUILD-PLAN-<solution>.md` | builder |
| `QA-SIGNOFF-<solution>.md`, `evals/` | qa |
| `VERIFICATION-<solution>-<date>.md` | sentinel |
| `SOLUTION-DOC.md` | architect (A–G, I, K.1/K.3–K.5) + qa (H, J, K.2) |
| `INCIDENTS.md`, `DECISIONS.md` | shared append-only logs |

## Develop / validate

```powershell
pwsh -NoProfile -File tests/validate.ps1
```

The validator checks each agent's frontmatter (name, model, tools, preloaded skills, memory) and the required sections from the spec's matrices. It also checks the dispatched-skill references, the 12-phase ADLC table and six escalation routes, and the templates. Finally, it installs, updates, and uninstalls with both installers in a temp folder.
