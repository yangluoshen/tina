---
name: tina-code-review
description: Review the original request's aggregate implementation diff for code smells and architectural quality through an independent reviewer. The main agent starts fresh fix agents, reruns story-level QA, and repeats review until Approved.
---

# Tina Code Review

Review all code changes produced by the original request after QA passes. Use
the request or Proposal Plan to resolve the full implementation scope and its
baseline. Review code smells, unnecessary complexity, duplication, coupling,
module boundaries, and unreasonable architecture. Functional completeness and
user-story acceptance belong to QA and `$tina-verify`, not this review.
The main agent owns the repair loop; implementation, QA, and review stay separate.

1. For every spawned agent, choose `model` and `reasoning_effort` from the
   `Tina Subagent Models` table in this repository's `AGENTS.md` based on the
   active profile.
2. Spawn or reuse one `tina_code_reviewer` for the request. Send the original
   request, baseline, all implementation/fix commits and current diff, applicable
   architecture/ADR context, and final QA report at `docs/qa/apply.md`. Establish
   the complete request-level diff from the plan, apply handoff, and Git history;
   exclude unrelated work and do not narrow review to individual Changes.
   If the baseline or scope cannot be established, report that blocker.
3. The reviewer stays read-only. The main agent records each finding in
   `docs/qa/issues/<request-slug>-review-<issue-slug>.md` with source `code review`,
   severity, file paths, evidence, rationale, and status. Findings have no owning
   implementation Change. For each required fix, start a new `tina_implementer`
   with the issue path and a bounded bug-fix assignment; do not reuse original
   implementation agents or create an OpenSpec Change just to route the fix.
4. Inspect and commit fixes, then run `$tina-qa` on the request's QA Change(s),
   reusing the QA agent and original story suite. After QA passes, ask the same
   reviewer to re-review the complete updated diff and resolve findings with
   evidence. Repeat until `Approved`; reuse each fix agent only for its issue.
5. If QA or review cannot proceed because a required prerequisite is unavailable,
   report the blocker and incomplete status; do not claim approval.
6. Return the verdict, issue paths, and unresolved concerns to the caller.
   Do not start verify or archive. Under `$tina-yolo`, return to its orchestrator.
