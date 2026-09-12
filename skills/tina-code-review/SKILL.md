---
name: tina-code-review
description: Review the original request's aggregate implementation diff for code smells and architectural quality through an independent reviewer. Record issues in docs/code-review/issues, automatically fix P0, defer P1/P2 with reminders, and validate affected code.
---

# Tina Code Review

Review all code changes produced by the original request. Use
the request or Proposal Plan to resolve the full implementation scope and its
baseline. Review code smells, unnecessary complexity, duplication, coupling,
module boundaries, and unreasonable architecture. The main agent owns the repair
loop; implementation and review use separate agents.

## Code Review Issues

Classify each finding by demonstrated impact within the original request:

- **P0**: blocks a core module or required user outcome; also includes
  demonstrated serious security or data-loss risks.
  Fix automatically within the authorized scope before passing the stage.
- **P1**: meaningful degradation or maintainability risk that does not block
  those outcomes. Defer by default.
- **P2**: minor defect or improvement with limited impact. Defer by default.

Every issue file must contain `Priority: P0|P1|P2` and
`Status: open|in_progress|resolved|deferred|blocked`, selecting one value each.
Include the impact supporting its priority. Use `open` for a new P0,
`in_progress` when assigned, `resolved` only after reviewer confirmation with
evidence, and `blocked` when a required fix cannot proceed, with the reason.
Record P1/P2 as `deferred` with the reason and a condition for revisiting them;
fix them only when the user requests it. Update the existing issue and preserve
its history; reopen it when new evidence invalidates resolution. Summaries and
final responses must link deferred issues with their priority and impact.
Deferred P1/P2 alone do not prevent review approval. Never lower priority or
resolve an unverified finding to obtain approval.

## Proportionate Validation

Prioritize core modules and the user's stated focus within the request's diff.
Accept that defects can remain; do not turn review into an open-ended audit.
Inspect the complete scoped diff and relevant code context. After a fix, run only
required checks and relevant regression checks, retaining unaffected review evidence.
Expand or repeat testing only when a new change fails or evidence shows it is
necessary to solve the issue; record that reason. Once relevant checks pass,
continue and complete the task. For limited, reversible changes, do not add tests
that merely mirror the implementation.

## Workflow

1. For every spawned agent, choose `model` and `reasoning_effort` from the
   `Tina Subagent Models` table in this repository's `AGENTS.md` based on the
   active profile.
2. Spawn or reuse one `tina_code_reviewer` for the request. Send the original
   request, baseline, all implementation/fix commits and current diff, applicable
   architecture/ADR context. Establish the complete request-level diff from the
   plan, apply handoff, and Git history;
   exclude unrelated work and do not narrow review to individual Changes.
   If the baseline or scope cannot be established, report that blocker.
3. The reviewer stays read-only. The main agent records each finding in
   `docs/code-review/issues/<request-slug>-<issue-slug>.md` with source `code review`,
   `Priority: P0|P1|P2`, `Status: open|in_progress|resolved|deferred|blocked`
   (one value each), impact, file paths, evidence, and rationale. Findings have no
   owning implementation Change. By default, mark P1/P2 `deferred` with the reason
   and revisit condition; fix them only when the user requests it. For each
   selected fix (P0 or user-requested P1/P2), mark it `in_progress` and start
   a new `tina_implementer`
   with the issue path and a bounded bug-fix assignment; do not reuse original
   implementation agents or create an OpenSpec Change just to route the fix.
4. Inspect the fixes and the implementer's relevant validation evidence, then
   commit the fixes. Ask the same reviewer to review the fixes and
   their interactions in the aggregate diff, retaining unaffected review evidence.
   The main agent updates existing issues to `resolved` only on reviewer
   confirmation with evidence, preserving history. Repeat only for unresolved P0
   or user-requested fixes. Expand or repeat testing only after a new change fails
   or evidence demonstrates the need. Deferred P1/P2 alone do not prevent
   `Approved`; reuse each fix agent only for its issue.
5. If review cannot proceed because a required prerequisite is unavailable,
   report the blocker and incomplete status; mark affected P0 issues `blocked`
   with the reason and do not claim approval.
6. Return the verdict, issue paths, and unresolved concerns to the caller,
   explicitly reminding them of deferred P1/P2 and their impact.
   Do not start verify or archive. Under `$tina-yolo`, return to its orchestrator.
