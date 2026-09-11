---
name: tina-qa
description: Execute a QA Change against the original request's user stories through an independent QA subagent. Record issues in docs/qa/issues; the main agent starts fresh bug-fix implementers and repeats QA until passed.
---

# Tina QA

Execute the planned QA Change after its implementation prerequisites are ready.
Accept its name or the Proposal Plan. The original request's user stories define
acceptance across the whole product flow, independent of implementation Change
boundaries. The main agent owns the repair loop; QA and fixes use separate agents.

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
   severity, affected user story, reproduction, expected/actual results, evidence,
   and status. Issues have no owning implementation Change. Keep the summary
   at `docs/qa/apply.md`, linking issue files and story evidence. QA marks its
   Change's tasks complete only with passing evidence.
4. For each required issue, the main agent starts a new `tina_implementer` with
   a bounded bug-fix assignment, the issue path, and relevant context. Do not
   return issues to original implementation agents or require a new OpenSpec
   Change for the fix. The fixer may touch any code needed for that issue within
   the original request's scope. Inspect and commit its fix, then ask the same
   QA agent to retest the original story suite, update issue status and evidence,
   and repeat until passed. Reuse a bug-fix agent only for follow-up on its issue.
5. If a required service, tool, or credential is unavailable, report the blocker
   and incomplete QA status; do not claim a pass.
6. Return the verdict, report path, and issue paths to the caller. Do not start
   code review, verify, or archive. Under `$tina-yolo`, return to its orchestrator.
