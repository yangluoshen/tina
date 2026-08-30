---
name: tina-propose-run
description: Execute a confirmed Tina proposal plan from docs/proposal-plan/<date>-<scenarios>.md as a long-running propose/review loop. Use only after tina-propose-plan has confirmed the split; do not grill or ask for individual confirmation.
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
4. For each Change in the plan order, spawn one `tina_proposer`, then spawn
   `tina_proposal_reviewer`. If the verdict is `Needs changes`, send the review
   back to the same proposer and repeat until `Approved`.
5. Parallelize different Changes only when they do not declare the same
   capability and do not touch the same files; otherwise process them serially.
6. Record the final review result for each Change in
   `docs/run/<change>-plan.md`.
7. Mark the goal complete only when the plan file's stopping condition is met.
   Never archive; verification and archive remain separate user actions.

