---
name: tina-qa
description: Execute a QA Change against the original request's user stories through an independent QA subagent. Record prioritized issues in docs/qa/issues; automatically fix P0, defer P1/P2 with reminders, and retest affected stories.
---

# Tina QA

Execute the planned QA Change after its implementation prerequisites are ready.
Accept its name or the Proposal Plan. The original request's user stories define
acceptance across the whole product flow, independent of implementation Change
boundaries. The main agent owns the repair loop; QA and fixes use separate agents.

## QA Issues

Classify each finding by demonstrated impact within the original request:

- **P0**: blocks a core module, a required user outcome, or an explicit acceptance
  criterion; also includes demonstrated serious security or data-loss risks.
  Fix automatically within the authorized scope before passing the stage.
- **P1**: meaningful degradation or maintainability risk that does not block
  those outcomes. Defer by default.
- **P2**: minor defect or improvement with limited impact. Defer by default.

Every issue file must contain `Priority: P0|P1|P2` and
`Status: open|in_progress|resolved|deferred|blocked`, selecting one value each.
Include the impact supporting its priority. Use `open` for a new P0,
`in_progress` when assigned, `resolved` only after QA confirmation with
evidence, and `blocked` when a required fix cannot proceed, with the reason.
Record P1/P2 as `deferred` with the reason and a condition for revisiting them;
fix them only when the user requests it. Update the existing issue and preserve
its history; reopen it when new evidence invalidates resolution. Summaries and
final responses must link deferred issues with their priority and impact.
Deferred P1/P2 alone do not prevent QA passing. Never lower
priority or mark failed acceptance complete to obtain a passing verdict.

## Proportionate Validation

Prioritize core modules and the user's stated focus within the agreed acceptance
scope. Accept that defects can remain; do not turn QA into an open-ended
audit. Complete required checks and planned story coverage. After a fix, rerun
only affected checks and retain still-valid evidence for unchanged stories.
Expand or repeat testing only when a new change fails or evidence shows it is
necessary to solve the issue; record that reason. Once relevant checks pass,
continue and complete the task. For limited, reversible changes, do not add tests
that merely mirror the implementation.

## Workflow

1. For every spawned agent, choose `model` and `reasoning_effort` from the
   `Tina Subagent Models` table in this repository's `AGENTS.md` based on the
   active profile.
2. Resolve the QA Change(s), original request, stories, and prerequisites from the
   plan and proposal. Spawn or reuse one `tina_qa` for the request. Send the QA
   artifacts for all selected journeys, original stories and acceptance criteria,
   repository context, and implementation/fix commits. Test complete journeys
   and interactions; do not
   partition QA by implementation Change. If the QA Change is missing, return
   to planning rather than inventing a per-Change checklist during execution.
3. QA writes each issue to `docs/qa/issues/<qa-change>-<issue-slug>.md`, with
   `Priority: P0|P1|P2`, `Status: open|in_progress|resolved|deferred|blocked`
   (one value each), impact, affected user story, reproduction, expected/actual
   results, and evidence. Issues have no owning implementation Change. Keep the
   summary at `docs/qa/apply.md`, linking issue files and story evidence, including
   deferred P1/P2 with their impact and revisit conditions. QA marks its Change's
   tasks complete only with passing evidence; deferred non-blocking issues alone
   do not fail QA.
4. By default, fix only P0; mark P1/P2 `deferred` and remind the caller rather
   than dispatching fixes unless the user requests them. For each selected fix
   (P0 or user-requested P1/P2), the main agent marks it `in_progress` and starts
   a new `tina_implementer` with
   a bounded bug-fix assignment, the issue path, and relevant context. Do not
   return issues to original implementation agents or require a new OpenSpec
   Change for the fix. The fixer may touch any code needed for that issue within
   the original request's scope. Inspect and commit its fix, then ask the same
   QA agent to retest affected stories and retain still-valid evidence for the
   rest. QA marks the issue `resolved` only after passing retest and preserves
   its history. Repeat only for unresolved P0 or user-requested fixes; expand
   testing only after a new change fails or evidence demonstrates the need.
   Reuse a bug-fix agent only for follow-up on its issue.
5. If a required service, tool, or credential is unavailable, report the blocker
   and incomplete QA status; mark affected P0 issues `blocked` with the reason
   and do not claim a pass.
6. Return the verdict, report path, and issue paths to the caller, explicitly
   reminding them of deferred P1/P2 and their impact. Under `$tina-yolo`, return to its orchestrator.
