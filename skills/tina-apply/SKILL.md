---
name: tina-apply
description: Implement approved Tina changes one at a time, run real-environment QA for each, commit each change, then run one final code review over the full set. Use only after the user explicitly authorizes implementation.
---

# Tina Apply

This workflow implements already approved Changes. Never run it without an
explicit authorizing request. Do not archive.

1. Create or use the active goal. The objective is to implement the selected
   Changes in dependency order, pass per-change QA and the final code review,
   and commit each Change before moving on.
2. For every spawned agent, choose `model` and `reasoning_effort` from the
   `Tina Subagent Models` table in this repository's `AGENTS.md` based on the
   active profile.
3. For each Change in dependency order:
   a. Derive a stable slug from the Change name: lowercase it and replace every
      character outside `[a-z0-9_]` with `_`. Use these agents only for this
      Change: `<slug>_implementer` and `<slug>_qa`.
   b. Spawn `tina_implementer` as `<slug>_implementer` and send it the Change.
   c. Spawn `tina_qa` as `<slug>_qa`. If QA fails, send its
      `docs/qa/<change>.md` back to `<slug>_implementer`, then ask the same
      `<slug>_qa` to re-test. Repeat until passed. Do not spawn replacements.
   d. Verify the worktree contains only this Change's expected files, then
      `git add` and commit with `tina(change): <change-name>`.
4. After all Changes are committed, spawn one `tina_code_reviewer` for the
   whole run, e.g. `apply_reviewer`. Send it every Change in this run, their
   commits, and their QA reports. If `Needs changes`, route each required fix
   to the relevant `<slug>_implementer`, rerun that change's `<slug>_qa`, and
   ask the same `apply_reviewer` to re-review. Repeat until `Approved`. Do not
   spawn replacements.
5. Write unresolved concerns and leftover questions to
   `docs/run/<change>-concerns.md` and summarize them for the user when the goal
   ends.
6. Leave archive and verify as separate user actions.
