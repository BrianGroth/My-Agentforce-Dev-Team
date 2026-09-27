# Incidents

Append-only log of failures, escalations, releases, rollbacks, and production findings. Newest entries at the bottom. Read the entries for any area before working in it.

**Who writes here:** 🧭 orchestrator (circuit-breaker trips, org-mismatch halts) · ✅ qa (escalated/stuck failures) · 🚀 shipper (every release and rollback) · 🛰️ sentinel (production incidents, governor findings, rollbacks, clean monitoring cycles).

## Entry template

```
### INC-<nnn> — <short title>
- Date: <YYYY-MM-DD>            Logged by: <agent display name>
- Type: release | rollback | test-escalation | circuit-breaker | production-incident | governor-limit | monitoring-clean
- Severity: S1 | S2 | S3 | n/a
- Org: <alias>                   Components: <API names>
- Evidence: <trace IDs, log lines, test/eval case IDs, job IDs>
- Impact: <who/what, since when>
- Route taken: R1–R6 → <agent>
- Resolution: <what fixed it, commit SHA / deploy ID>   Status: open | resolved
- Eval case added: <case ID or n/a>
```

---
