---
name: coding-workflow-verify
description: Verify an implemented OpenSpec change against its tasks, behavioral specs, design, and domain model before archive. Use when implementation is complete or the user asks whether a change is ready to archive.
---

# Workflow Verify

Verification is read-only except for running safe checks. Never archive or alter
the implementation during this workflow.

1. Resolve the Change from the request or `openspec list --json`; if ambiguous,
   ask the user to choose.
2. Run `openspec status --change <name> --json` and
   `openspec instructions apply --change <name> --json`. Read every returned
   context file plus applicable CONTEXT and ADR files.
3. Report as **Critical** any unchecked task or missing requirement behavior.
4. For every completed task, run or inspect its stated verification. Map each
   requirement and scenario to observable implementation and test evidence.
5. Report as **Warning** any design, vocabulary, or ADR divergence and any
   scenario without evidence. Use **Suggestion** only for non-blocking issues.

Conclude either `Ready to archive` or `Not ready to archive`, with concrete file
and command evidence. Do not treat artifact existence or checked boxes alone as
proof of correctness.
