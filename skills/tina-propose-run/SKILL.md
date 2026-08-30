---
name: tina-propose-run
description: Execute a confirmed Tina proposal plan from docs/proposal-plan/<date>-<scenarios>.md, propose all Changes, then run one final global review. Use only after tina-propose-plan has confirmed the split; do not grill or ask for individual confirmation.
---

# Tina Propose Run

This workflow executes an already confirmed proposal plan. Never renegotiate the
split, grill the user, or archive.

1. Require the user to provide
   `docs/proposal-plan/<date>-<scenarios>.md`. If it is missing, stop and ask for
   the confirmed plan; do not invent one.
2. Create or use the active goal. Read the outcome, success criteria, and
   stopping condition from the plan file; do not replace them with a generic
   rule.
3. For every spawned agent, choose `model` and `reasoning_effort` from the
   `Tina Subagent Models` table in this repository's `AGENTS.md` based on the
   active profile.
4. For each Change in the plan order, derive a stable slug from the Change
   name: lowercase it and replace every character outside `[a-z0-9_]` with `_`.
   Spawn one `tina_proposer` as `<slug>_proposer` and send it that Change. Do
   not spawn a reviewer per Change.
5. Parallelize different Changes only when they do not declare the same
   capability and do not touch the same files; otherwise process them serially.
6. After all Changes are proposed, spawn one `tina_proposal_reviewer` for the
   whole run, e.g. `propose_reviewer`. Send it every Change and its artifacts.
   If `Needs changes`, route each required edit to the relevant
   `<slug>_proposer`, then ask the same `propose_reviewer` to re-review. Repeat
   until `Approved`. Do not spawn replacements.
7. Record the final review result for the run in `docs/run/propose-plan.md`.
8. Mark the goal complete only when the plan file's stopping condition is met.
   Never archive; verification and archive remain separate user actions.
