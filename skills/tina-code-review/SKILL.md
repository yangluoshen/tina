---
name: tina-code-review
description: Review selected Tina Changes through an independent code reviewer. The main agent routes required fixes to implementers, reruns QA, and repeats review until Approved.
---

# Tina Code Review

Review the selected Changes and their implementation/fix commits after full QA
passes. The main agent owns the repair loop; implementation, QA, and code review
stay in separate subagents.

1. For every spawned agent, choose `model` and `reasoning_effort` from the
   `Tina Subagent Models` table in this repository's `AGENTS.md` based on the
   active profile.
2. Spawn one `tina_code_reviewer` for the whole scope, e.g. `apply_reviewer`.
   Send it every Change, commit, and the final QA report at `docs/qa/apply.md`.
3. If `Needs changes`, route each required fix to the relevant
   `<slug>_implementer` from apply. If a prior session's implementer is
   unavailable, spawn `tina_implementer` for that Change only. Run `$tina-qa`
   over the same full scope with the updated code, reusing its QA agent. After
   QA passes, ask the same reviewer to re-review the full diff and QA report.
   Repeat until `Approved`; reuse the same agents throughout the loop.
4. If QA or review cannot proceed because a required prerequisite is unavailable,
   report the blocker and incomplete status; do not claim approval.
5. Return the verdict and unresolved concerns to the caller. Do not start verify
   or archive. Under `$tina-yolo`, return to its orchestrator.
