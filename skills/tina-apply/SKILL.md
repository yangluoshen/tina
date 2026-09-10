---
name: tina-apply
description: Implement approved Tina changes one at a time through independent implementers, commit each change, then return control. Use only after the user explicitly authorizes implementation.
---

# Tina Apply

This workflow implements already approved Changes. Never run it without an
explicit authorizing request. Do not archive.

1. Create or use the active goal. The objective is to implement the selected
   Changes in dependency order and commit each Change before moving on.
2. For every spawned agent, choose `model` and `reasoning_effort` from the
   `Tina Subagent Models` table in this repository's `AGENTS.md` based on the
   active profile.
3. For each Change in dependency order:
   a. Derive a stable slug from the Change name: lowercase it and replace every
      character outside `[a-z0-9_]` with `_`. Use this agent only for this
      Change: `<slug>_implementer`.
   b. Spawn `tina_implementer` as `<slug>_implementer` and send it the Change.
   c. Verify the worktree contains only this Change's expected files, then
      `git add` and commit with `tina(change): <change-name>`.
4. Write unresolved concerns and leftover questions to
   `docs/run/<change>-concerns.md` and summarize them for the user when the goal
   ends.
5. Return the Change/commit list and implementer assignments to the caller.
   Leave QA, code review, verify, and archive as separate user actions. Under
   `$tina-yolo`, return to its orchestrator to continue the workflow.
