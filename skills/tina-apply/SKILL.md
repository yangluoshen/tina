---
name: tina-apply
description: Implement approved Tina changes one at a time, commit each change, then run one final full QA and code review over the full set. Use only after the user explicitly authorizes implementation.
---

# Tina Apply

This workflow implements already approved Changes. Never run it without an
explicit authorizing request. Do not archive.

1. Create or use the active goal. The objective is to implement the selected
   Changes in dependency order, pass one final full QA and code review, and
   commit each Change before moving on.
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
4. After all Changes are committed, spawn one `tina_qa` for the whole run,
   e.g. `apply_qa`. Send it every Change and commit in this run. If QA fails,
   route each required fix to the relevant `<slug>_implementer`, then ask the
   same `apply_qa` to re-test. Repeat until passed. Do not spawn replacements.
5. After QA passes, spawn one `tina_code_reviewer` for the whole run, e.g.
   `apply_reviewer`. Send it every Change, commit, and the final QA report. If
   `Needs changes`, route each required fix to the relevant
   `<slug>_implementer`, rerun the same `apply_qa`, and ask the same
   `apply_reviewer` to re-review. Repeat until `Approved`. Do not spawn
   replacements.
6. Write unresolved concerns and leftover questions to
   `docs/run/<change>-concerns.md` and summarize them for the user when the goal
   ends.
7. Leave archive and verify as separate user actions.
