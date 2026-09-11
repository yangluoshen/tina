---
name: univer-craft-yolo
description: Autonomously build or change a Univer App through verified completion using Tina YOLO, with demand-driven Univer SDK research. Use when the user requests Univer Craft YOLO or delegates the full Univer task without intermediate handoffs.
---

# Univer Craft YOLO

Use Univer-specific context to delegate the requested outcome to `$tina-yolo`.
This mode depends on both `$univer-craft` and `$tina-yolo`; it does not maintain
a second execution workflow.

Read the installed `$univer-craft` skill's **Shared context and research** and
**Repository defaults** sections, including its SDK research map as relevant.
Apply those sections without running its normal dispatch or next-step handoff.
When installed together, the shared skill is at
`../univer-craft/SKILL.md`; otherwise locate it through available skills.

Read and invoke the installed `$tina-yolo` with the original request, target
repository, acceptance criteria, existing Change/Proposal Plan paths, SDK layers
and versions, relevant sources, and existing Research Notes. Pass unresolved
SDK questions to its research stage; carry out bounded research as required by
the shared guidance. Do not research every SDK or repeat sufficient research.

Invoking this mode delegates the requested task under Tina YOLO's authorization
and routing rules. Apply its overrides to nested Tina stages and agents. Let the
orchestrator decide scope details, architecture, UX, and engineering choices,
recording assumptions and evidence in Tina's existing run record. New apps use
pnpm and TypeScript by default; existing apps retain their conventions. Do not
ask preference questions or stop with instructions for the user to invoke the
next stage.

Tina YOLO owns planning, implementation, local commits, independent QA/review,
verification, fix loops, and continuation. Preserve its completion criteria and
permission boundaries; requesting this wrapper does not authorize pushing,
deployment, destructive actions, or archive. On continuation, resume the
existing run after checking its artifacts and evidence.

If a required SDK capability, license, credential, service, or Tina prerequisite
is unavailable, record the exact blocker and finish independent work. Do not
replace requested integration with a mock and declare completion. Return the
delivered behavior, checks, Research Note/run paths, and any incomplete work in
the user's language, without an intermediate stage handoff.
