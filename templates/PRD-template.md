# PRD — <solution>

> Owned by 🏛️ The Architect Agent. Durable contract the team builds from. Version: v1 · Target org: <alias> · Status: draft | awaiting approval | approved (<date>)

## 1. Summary & goal
<One paragraph.> **Success criteria:** <measurable outcomes>

## 2. Discovery findings (target org: <alias>)
- Org identity: <org ID, edition, sandbox/prod, API version>
- Capabilities & licences: <Agentforce, Einstein Agent licences, Data 360, Experience Cloud (sites used / cap), MIAW, Voice>
- Existing agents: <BotDefinitions / active versions>
- Data model touched: <objects, fields, OWD, sharing, automation>
- Reusable assets: <invocable Apex, Flows, Prompt Templates, Named Credentials>
- Known history: <INCIDENTS/DECISIONS refs>

## 3. Scope
- In scope / out of scope
- Personas
- Channel

## 4. Agentforce agent spec
- Agent type: <Employee / Service> · `access.default_agent_user`: <queried username or "omit (employee)">
- Entry (`start_agent`): <acts directly | routes to subagents> — router instructions
- Patterns used: <single-subagent / router-first / verification gate / action chaining / required-subagent workflow / knowledge-grounded / handoff>

| Subagent | Purpose | Instructions (static `|`) | Deterministic logic (no nested if) | Actions |
|---|---|---|---|---|

| Action | Target (type + API name) | Inputs | Outputs | new / reuse |
|---|---|---|---|---|

- Variables / state:
- Guardrails:
- Off-topic handling: <scope boundary + exact redirect>
- Human handoff: <trigger + destination>

## 5. Backing-asset inventory

| Asset | Type | API name | new / modify / reuse | Notes |
|---|---|---|---|---|

## 6. Data & sharing/security model
- OWD / sharing rules:
- Permission sets & assignments:
- Agent user permissions:
- FLS / data exposure boundaries:
- ECA / hosted MCP access (if any):

## 7. RAG / grounding
- Source: <none / Data 360 retriever / ADL> — why
- What builder authors vs. what is manual (see § 9)

## 8. Channel design
- MIAW / ESD: deploymentType, clientVersion, areGuestUsersAllowed, Messaging Channel, pre-chat, routing, SCRT2 URL
- Site: new/existing, guest profile, embedding approach (headMarkup / LWC), CSP
- Voice: modality, formatting rules, telephony, latency masking
- Slack / API specifics

## 9. Manual org-config steps

| # | Step | Before/after deploy | How to verify |
|---|---|---|---|

## 10. Eval-set requirements (20–50 cases)

| Category | # cases | Examples |
|---|---|---|
| Happy path per subagent | | |
| Edge cases | | |
| Off-topic | | |
| Human handoff | | |
| Grounding (answerable / not-in-corpus) | | |
| Adversarial — OWASP LLM categories | | |

## 11. Non-functional
- Volumes, limits, latency budget, Well-Architected notes / grade

## 12. Open questions & assumptions

## 13. Implementation notes for builder

## 14. Changelog

| Version | Date | Change | Approved |
|---|---|---|---|
| v1 | | Initial | |
