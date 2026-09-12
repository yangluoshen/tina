---
name: tina-yolo
description: Autonomously carry a task through tina-research, tina-propose-plan, tina-propose-run, tina-apply, tina-qa, tina-code-review, and tina-verify. Use when the user requests Tina YOLO mode or delegates the complete workflow without intermediate questions; skip grilling, decide trade-offs, and keep working until verified completion.
---

# Tina YOLO

Own the requested outcome through verified completion. Requesting this mode
authorizes research, planning, implementation, local Change commits, and
verification for that task. Apply the YOLO routing exceptions in the Target
Instructions to every stage and assigned agent. Do not invoke `$grilling` or
`$grill-with-docs`, ask preference questions, wait for confirmation, or end a
stage with a prompt for the user to run the next stage.

Use the judgment of a world-class software engineer and designer: ground choices
in the user's outcome, repository evidence, and established product conventions.
Prefer clear interactions, accessible defaults, coherent boundaries, and the
smallest maintainable implementation that meets the outcome. Resolve ambiguity
with a concrete assumption and record its consequences. Verify external facts
through research; confidence and taste are not evidence.

## Run record

Use `docs/proposal-plan/<date>-<scenarios>.md` as the run's source of truth.
Alongside the normal Proposal Plan, maintain:

- `Mode: tina-yolo`, the original request, scope, constraints, and measurable
  acceptance criteria;
- `Decisions`: the question, chosen option, evidence or assumption, alternatives
  rejected, trade-offs, and conditions that would justify revisiting it;
- `Execution`: current stage, ordered Change names and dependencies, artifact and
  research paths, Change types and QA story coverage, baseline commit,
  implementation/fix commits, issue paths with priority and status, review verdicts,
  verification commands and results, and unresolved blockers.

Record decisions when made, including architecture, UX, scope splits, and
verification trade-offs. Mark model decisions as `model-decided (tina-yolo)`;
never claim human confirmation. Keep settled vocabulary in CONTEXT files and
promote decisions that are hard to reverse, surprising without context, and a
real trade-off into `docs/adr/`. Cite ADRs from the plan and designs instead of
duplicating their rationale. Keep design conditional under the Tina schema.

On continuation, read this record and inspect actual artifacts, Git state, and
test evidence before resuming the earliest incomplete or invalidated stage.
Retain the original acceptance criteria; do not weaken them to declare success.
Use an active goal when supplied, but do not create a goal merely because this
skill was invoked. Only the orchestrator can complete the whole-run goal; stage
completion must not complete it.

## Dispatch

After implementation, QA and code review can run in either order. Dispatch each
with its own inputs and record its own verdict; neither requires the other's
report or approval. A fix does not automatically trigger the other workflow.

1. **`$tina-research`**: inspect relevant code, specs, CONTEXT files, and ADRs.
   Resolve external or unstable facts with cited Research Notes when needed;
   local inspection suffices otherwise. Carry the findings and paths forward.
2. **`$tina-propose-plan`**: use its ordered-list planning path even for one
   implementation Change. Plan a separate QA Change from the original user
   stories, with prerequisites on the implementation needed for those stories.
   Write the run record and split work within the normal size gate.
   Use `$domain-modeling` directly as needed, with no grilling. If architecture
   alignment is required, invoke `$tina-architecture`, review the architect's
   model and semantic choices yourself, and return revisions to the same agent
   until sound. Record model acceptance, JSON path, `specification_sha256`, and
   assigned stable IDs in `Architecture Alignment`. Decide and record the split
   yourself. Leave artifact creation to the next stage.
3. **`$tina-propose-run`**: pass the plan path explicitly and reuse its proposer
   and global proposal-reviewer loop. Proposers create their assigned Change's
   artifacts using `$tina-propose-plan`'s assigned-Change path with these overrides;
   they do not start another YOLO run or rewrite the run plan. Distinguish the
   proposal-stage exit criterion (`Approved` for the full set) from whole-run
   completion. If artifacts expose excess scope or the architecture hash has
   changed, return to planning, reconcile the model and split, then re-review
   the affected proposals. Continue to apply only after global approval.
4. **`$tina-apply`**: pass only the ordered implementation Changes. Use the existing
   independent implementers and commit each Change, then dispatch the checks below.
   Record the baseline and preserve unrelated work; stage only files belonging
   to this run. Planning artifacts and run reports belong to this run, but
   unrelated dirty files must never be swept into its commits.
5. **`$tina-qa`**: pass the QA Change(s), original request, user stories, plan,
   and implementation/fix commits. Execute acceptance across complete journeys.
   Use its independent QA and fresh bug-fix agent loop; issues live in
   `docs/qa/issues` without implementation Change ownership. Automatically fix
   P0 only; defer P1/P2 with reasons and revisit conditions unless the user
   requests those fixes. Commit fixes before affected-story retests, retain
   still-valid evidence, and record the verdict for each QA Change.
6. **`$tina-code-review`**: pass the original request, baseline, complete
   implementation/fix diff, and architecture context. Review code smells and
   architectural quality. Record findings in `docs/code-review/issues` using
   the skill's priority/status policy and independent reviewer/P0 repair loop.
   Inspect fixes and relevant validation evidence, commit them, and re-review
   affected code in the aggregate diff. Record the verdict; deferred P1/P2 do
   not trigger another repair or review cycle.
7. **`$tina-verify`**: pass each exact Change name from the plan, with no
   interactive selection. Keep verification read-only. Persist its evidence and
   verdict in the run record as the orchestrator. Return incomplete QA tasks or
   missing story evidence to `$tina-qa`. For missing implementation behavior,
   unchecked implementation tasks, divergence, or missing scenario evidence,
   route fixes back to apply (or planning if scope/design must change), commit
   fixes, route demonstrably invalidated evidence to the relevant workflow, then
   verify affected Changes again. Retain still-valid evidence; expand or repeat
   testing only when a new change fails or evidence demonstrates the need.

Use the installed Tina roles and the active profile's model table. Pass the
YOLO mode, plan path, bounded assignment, relevant decisions, and original scope
authorization to every agent. Agents return unresolved choices to the
orchestrator, who decides and records them without questioning the user.
Preserve independent review verdicts; the orchestrator must resolve P0 findings,
not override a failing verdict with its own confidence.

## Completion and blockers

Continue without stage handoff pauses until every implementation Change is
implemented and committed, every QA Change has passing story evidence and
completed acceptance tasks, global proposal review is Approved, code
review is Approved on the final implementation, and every Change's verification
is Ready to archive with requirement/scenario evidence. Resolve every QA/review
P0; retain P1/P2 as deferred unless the user requests their repair. Resolve
Critical and Warning verification failures in required behavior or evidence;
do not promote deferred QA/review issues into blockers merely to clear the backlog.
Save the final run record and commit remaining run documentation before reporting
completion.
Report delivered behavior, verification results, decision/ADR paths, and any
deferred P1/P2 issue paths, priorities, and impact in Chinese by default.

For a failing check, diagnose and fix the cause and continue. If progress needs
unavailable credentials, a missing required tool/service, or authority beyond
the request, record the exact blocker and attempted remedies, finish independent
work, and report incomplete status without asking an intermediate question or
claiming success. Follow the runtime's own rules for any goal status update.
YOLO does not grant additional tool permissions or authorize destructive actions,
publishing, pushing, deployment, or archive. The mode ends with this task or when
the user cancels it; do not persist it as a project default.
