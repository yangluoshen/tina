---
name: tina-apply
description: Implement approved Tina changes one at a time, run real-environment QA and code review, and commit each change before moving on. Use only after the user explicitly authorizes implementation.
---

# Tina Apply

This workflow implements already approved Changes. Never run it without an
explicit authorizing request. Do not archive.

1. Create or use the active goal. The objective is to implement the selected
   Changes in dependency order, pass QA and code review, and commit each Change
   before moving on.
2. For every spawned agent, choose `model` and `reasoning_effort` from the
   `Tina Subagent Models` table in this repository's `AGENTS.md` based on the
   active profile.
3. For each Change in dependency order:
   a. Spawn `tina_implementer`.
   b. Spawn `tina_qa`; if QA failed, return its `docs/qa/<change>.md` to the
      implementer and repeat until passed.
   c. Spawn `tina_code_reviewer`; if `Needs changes`, return the review to the
      implementer and repeat until `Approved`.
   d. Verify the worktree contains only this Change's expected files, then
      `git add` and commit with `tina(change): <change-name>`.
4. Write unresolved concerns and leftover questions to
   `docs/run/<change>-concerns.md` and summarize them for the user when the goal
   ends.
5. Leave archive and verify as separate user actions.

