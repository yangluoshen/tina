---
name: tina-dsh-runtime
description: Adapt Tina stage skills and roles to a DSH Tina Mode session. Load before any Tina task in DSH, including assigned child tasks and resumed runs.
user-invocable: false
---

# Tina DSH Runtime

Read [target-instructions.md](target-instructions.md), installed alongside this
skill from the bundle's Target Instructions. This adapter owns only DSH-specific
tool, path, model, and recovery semantics. It overrides Codex-specific invocation
and model-table instructions in Tina skills, while preserving their workflow rules.
Missing runtime instructions, stage skills, or referenced resources are a broken
installation: report the missing path and do not improvise a replacement workflow.

## Scope and resource loading

Use this adapter only in a DSH Tina Mode session. Selecting the preset authorizes
no task. Normal stage handoffs, explicit implementation authorization, and separate
archive authorization still apply. Only a user-delegated `tina-yolo` task applies
its model-decided confirmation exceptions, limited to that task and its children.

The preset contributes its own skill directory. Load each required skill with
`skill({ name: "exact-name" })` before following it; the catalog is not the body.
User `/tina-name` input may already inject that body's instructions; do not reload
an already injected body just to satisfy a tool convention. `$name` in a Tina or
upstream document is a reference to the named skill, not a DSH slash command.
Render user-facing next-step examples as `/tina-name`, including a nested skill
reference inside a `/goal` request. Follow the actual tool schemas, not Codex API
examples found in upstream prose.

For Tina and its bundled OpenSpec/upstream dependencies, verify the loaded base
directory is a sibling of this skill under this preset's `skills/`. A mismatched
source is an installation conflict. Resolve scripts, templates, LOGIC.md/UI.md,
and other relative resources against the loaded skill's base, not the workspace
or a presumed `.agents/skills` directory. The generated `openspec-*` skills remain
unmodified; execute their CLI commands from the target project and require its
default schema to resolve to `tina`. Use the CLI version supplied by installation;
do not install or update global software as part of a workflow.

Read project instructions, applicable CONTEXT files, and ADRs normally. This
preset does not automatically discover project/user skill directories. If a task
needs an additional skill or browser capability, check actual availability;
report an unavailable prerequisite rather than inventing a tool or a passing test.
For `grill-with-docs`, load `grilling` and `domain-modeling` explicitly in DSH too.

Tina planning writes plan/proposal/prototype artifacts in ordinary execution mode.
If DSH `/plan` is active, its read-only guidance remains in force. Explain that
writing Tina artifacts needs the user to leave that mode; do not silently change
mode, treat conversational confirmation as DSH approval, or start implementation.

## Delegation and role results

| Tina assignment | DSH tool |
| --- | --- |
| Architecture Model | `tina_architect` |
| Throwaway prototype | `tina_prototype` |
| One implementation or QA proposal | `tina_proposer` |
| Global proposal review | `tina_proposal_reviewer` |
| One implementation Change or fresh P0 fix | `tina_implementer` |
| Story-level acceptance | `tina_qa` |
| Complete request diff review | `tina_code_reviewer` |
| Bounded research | `subagent` |

Call the role tool with `description`, `prompt`, and **`run_in_background: true`**.
The returned `subagentId` is the durable child id. Never use foreground execution
for a Tina role that must be reused: setting `run_in_background: false` takes the
one-shot path even though the tool is configured as continuable.

Stable task slugs are labels in the assignment/run record, not API agent ids.
Include the role, bounded scope, plan and artifact paths, original request and
acceptance criteria, mode/authorization, parent decisions, and required output.
Record the returned id before progressing. Parallelize only disjoint files and
capabilities; await all proposal outcomes before starting one global reviewer.

Use `send_message({ agent_id, message })` for feedback to the same direct child.
The coordinator must not edit proposer-owned proposal, specs, design, or tasks
artifacts, including fixes requested by review. Send each finding to the recorded
proposer, await their revision, then send the full revised proposal set to the
same global reviewer. Do not start apply before that reviewer's independent
approval. Delegate each implementation Change and each product-code P0 repair to a fresh
`tina_implementer`; the coordinator records decisions/evidence and commits rather
than editing product code.

Delivery acknowledgment is not a verdict. DSH sends a completion notice including
the outcome and final response; let that notice resume the coordinator rather
than polling `list_agents` or collecting a child id through `job_output`.
If a child is running and no independent work remains, state the pending work and
end the current assistant turn, leaving the task and goal incomplete. Let the
completion notice resume work without a new user request. Do not use `bash sleep`,
`list_agents` polling, or `job_output` to simulate waiting.
`list_agents` recalls ids/status on recovery; `ready` means
stored and resumable, not approved or complete.

Assigned children execute their role directly. They must not invoke the wrapper
that delegates their own role, spawn other roles, create goals, or complete the
parent's goal. They can use `send_message` to return questions/evidence requests
to their direct parent; they do not question the user or expand their assignment.
The parent decides within existing authorization, or handles any necessary human
decision. Parent-side commits include only files belonging to the task.

The two reviewers have only `read`, `read_image`, `glob`, `grep`, `skill`, and
`send_message`. They cannot execute shell, write files, or delegate. The parent
must supply the aggregate Git diff/baseline and may execute a requested diagnostic
or test command within the authorized scope, returning exact command, cwd, exit
status and output. The reviewer independently evaluates this evidence; requests
for evidence are not implementation or archive authorization. The parent persists
review issues/verdicts. QA can prepare environments and write acceptance records,
but product fixes go to fresh implementers. Keep P0 repair and P1/P2 deferral rules.

## Models and goals

Use each role tool's configured route; omitted options inherit the parent route.
The Codex `Tina Subagent Models` table does not select DSH providers. Do not pass
`agent_type`, `fork_turns`, `model`, or `reasoning_effort` unless that tool's actual
schema accepts the field. Model changes belong to the preset's `agentOptions`
and Host's available providers. A requested unavailable route is a blocker, not
permission to choose another model. Record known actual routes without fabricating
values that the Host does not expose.

Only the coordinator owns a same-session goal. Read `get_goal` before deciding
whether one exists and before every update. DSH `update_goal` takes exact
`goal_id`, `revision`, and `action`; it does not take Codex `status`. Its round cap
is `max_goal_rounds`, not `token_budget`. Respect the tool's direct-human-input
requirements and blocked-round threshold. Reuse an active goal for stages;
proposal approval alone never completes a goal whose scope includes implementation
and verification. Invoking `tina-yolo` alone does not require creating a new goal.

## Run record and recovery

Keep existing Proposal Plan and OpenSpec artifacts authoritative. Extend the plan's
Execution section with the DSH session id when available, role/slug/child-id map,
current stage, pending feedback, latest independent verdicts, actual known model
routes, original authorization/mode, baseline and Change/fix commits, and evidence.
Do not introduce a second state store or replace scenario evidence with goal status.

On continuation or compaction, reload this adapter, the plan, current stage skill,
relevant artifacts, Git state and still-valid evidence. Validate architecture hashes
and accepted prototype constraints before proceeding. Query `list_agents` and send
feedback only to the recorded direct child; report unavailable/corrupt child state
as a recovery blocker. Do not replace a reviewer silently. A restarted or forked
session may have a disarmed goal or different parentage; resume only with the
runtime-required user continuation authority, never by bypassing lineage checks.

Respect cancellation. Do not use Stop hooks or new child/goal creation to restart
a cancelled run. Finish only with the original stopping condition and independent
verdicts satisfied; missing credentials, browser/service capability, or evidence
leave the run incomplete. Verification does not authorize archive, push, or deploy.
