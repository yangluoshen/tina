---
name: tina-verify
description: Verify an implemented OpenSpec change against its tasks, behavioral specs, design, and domain model before archive. Use when implementation is complete or the user asks whether a change is ready to archive.
---

# Tina Verify

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
   For a QA Change, use its original user stories, acceptance tasks, QA report,
   and `docs/qa/issues` resolution evidence, including when `skip_specs: true`.
   Verify story-level results; do not require a product code delta from QA work.
   Retain QA/review issue priorities and statuses in `docs/qa/issues` and
   `docs/code-review/issues`. Deferred P1/P2 alone do not block verification or
   require repairs; report their paths and impact as follow-up. This does not
   waive missing acceptance evidence, unchecked tasks, or required behavior.
   Reuse still-valid evidence and check only affected behavior. Expand or repeat
   testing only when a new change fails or evidence demonstrates it is necessary
   to solve the issue; record the reason. Once required checks pass, complete
   verification without an unrelated audit.
5. Report as **Warning** any design, vocabulary, or ADR divergence and any
   scenario without evidence. Use **Suggestion** only for non-blocking issues.

Conclude either `Ready to archive` or `Not ready to archive`, with concrete file
and command evidence. Do not treat artifact existence or checked boxes alone as
proof of correctness.
