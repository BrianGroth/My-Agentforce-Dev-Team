# Decisions

Append-only log of non-obvious decisions (ADR-lite). Newest entries at the bottom. Supersede an old decision with a new entry that references it; never edit history.

**Who writes here:** 🧭 orchestrator (gate approvals, re-scoping) · 🏛️ architect (design decisions) · ✅ qa (coverage/scope decisions, accepted gaps, security-test confirmations) · 🚀 shipper (release-strategy decisions). 🔨 builder flags decisions to architect for logging.

## Entry template

```
### DEC-<nnn> — <short title>
- Date: <YYYY-MM-DD>            Decided by: <agent display name> / user
- Status: accepted | superseded by DEC-<nnn>
- Context: <what forced a decision>
- Decision: <what we chose>
- Alternatives considered: <option — why not>
- Consequences: <what this makes easier/harder; follow-ups>
```

---
