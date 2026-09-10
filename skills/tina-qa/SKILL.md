---
name: tina-qa
description: Run full acceptance QA over selected Tina Changes through an independent QA subagent. The main agent routes required fixes to implementers and repeats QA until passed.
---

# Tina QA

Run QA over the selected Changes and their implementation/fix commits. The main
agent owns the repair loop; QA and implementation stay in separate subagents.

1. For every spawned agent, choose `model` and `reasoning_effort` from the
   `Tina Subagent Models` table in this repository's `AGENTS.md` based on the
   active profile.
2. Spawn one `tina_qa` for the whole scope, e.g. `apply_qa`, or reuse this
   scope's existing QA agent. Send it every Change and commit in the run.
   The QA report remains `docs/qa/apply.md`.
3. If QA fails, route each required fix to the relevant `<slug>_implementer`
   from apply, then ask the same QA agent to re-test the whole scope. Repeat
   until passed. Reuse the same agents throughout the loop; if a prior session's
   implementer is unavailable, spawn `tina_implementer` for that Change only.
4. If a required service, tool, or credential is unavailable, report the blocker
   and incomplete QA status; do not claim a pass.
5. Return the verdict and report path to the caller. Do not start code review,
   verify, or archive. Under `$tina-yolo`, return to its orchestrator.
