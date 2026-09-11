---
name: tina-propose-run
description: Execute a confirmed Tina proposal plan from docs/proposal-plan, propose its implementation and QA Changes, then run one final global proposal review. Use only after tina-propose-plan has confirmed the split; do not grill or ask for individual confirmation.
---

# Tina Propose Run

This workflow executes an already confirmed proposal plan. Never renegotiate the
split, grill the user, or archive.

1. Require the user to provide
   `docs/proposal-plan/<date>-<scenarios>.md`. If it is missing, stop and ask for
   the confirmed plan; do not invent one.
2. When the plan contains `Architecture Alignment`, require its canonical JSON
   path to exist and recompute its SHA-256 with the Node.js standard library. If
   it differs from the recorded `specification_sha256`, stop and return to
   `$tina-propose-plan`; never propose against an architecture model changed
   after human confirmation.
3. Create or use the active goal. Read the outcome, success criteria, and
   stopping condition from the plan file; do not replace them with a generic
   rule.
4. For every spawned agent, choose `model` and `reasoning_effort` from the
   `Tina Subagent Models` table in this repository's `AGENTS.md` based on the
   active profile.
5. For each Change in the plan order, derive a stable slug from the Change
   name: lowercase it and replace every character outside `[a-z0-9_]` with `_`.
   Spawn one `tina_proposer` as `<slug>_proposer` and send it that Change plus
   its type, plan path, original request, user stories, and acceptance criteria,
   and the confirmed Architecture Model path and assigned stable IDs when present.
   Include the separate QA Change in this proposal loop; its proposer designs
   acceptance across the original stories, not per implementation Change.
   Do not spawn a reviewer per Change.
6. Parallelize different Changes only when they do not declare the same
   capability and do not touch the same files; otherwise process them serially.
7. After all Changes are proposed, spawn one `tina_proposal_reviewer` for the
   whole run, e.g. `propose_reviewer`. Send it the plan, original request, every
   Change, and its artifacts. Require QA coverage of the original user stories
   across the full implementation, including interactions between Changes.
   If `Needs changes`, route each required edit to the relevant
   `<slug>_proposer`, then ask the same `propose_reviewer` to re-review. Repeat
   until `Approved`. Do not spawn replacements.
8. Record the final review result for the run in `docs/run/propose-plan.md`.
9. Mark the goal complete only when the plan file's stopping condition is met.
   Never archive; verification and archive remain separate user actions.
