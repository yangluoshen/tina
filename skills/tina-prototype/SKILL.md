---
name: tina-prototype
description: Build and confirm a throwaway logic or UI prototype from the grilled Proposal Plan after tina-propose-plan and before tina-propose-run. Use to validate state models, interactions, or UI direction before creating Change artifacts.
---

# Tina Prototype

This stage authorizes throwaway prototype code and its confirmation record.
Do not create OpenSpec Changes or implement production behavior.

1. Require the confirmed `docs/proposal-plan/<date>-<scenarios>.md` from
   `$tina-propose-plan`. If it is missing or its stories, acceptance criteria, or
   constraints remain unsettled, return to planning and grilling before building.
   Read the plan, original request, linked Research Notes, applicable CONTEXT
   files and ADRs, and relevant code. Derive the bounded prototype question from
   the plan's stories and acceptance criteria, then choose logic or UI.
2. Reuse a confirmed prototype only when its question, scope, and decisions still
   apply. If there is no logic, state, interaction, or UI question to validate
   (for example, a documentation-only change), record `not applicable` with the
   concrete reason. Never skip a prototype the user explicitly requested.
   For reuse or `not applicable`, go directly to recording and handoff below.
3. Load `$prototype` and its `LOGIC.md` or `UI.md` branch. If any required file is
   missing, report a broken Tina installation. Follow the upstream method with
   the lifecycle overrides below.
4. Build the smallest runnable artifact that answers the question. Logic uses
   a self-contained HTML file; UI uses the existing application conventions in
   an isolated worktree or scratch copy. Keep prototype changes out of the
   production working tree, use in-memory state or stub writes, and preserve
   unrelated work. Open and exercise the relevant scenarios or variant controls
   before handing over the file or URL and run command.
5. Show the concrete prototype and request confirmation of the state rules,
   interaction, or selected UI variant. Iterate on feedback until the user
   explicitly confirms. Building or running successfully is not confirmation.
   In a user-requested `$tina-yolo` run, the orchestrator evaluates it and records
   `model-decided (tina-yolo)` instead; never claim human confirmation.
6. Save `docs/prototypes/<date>-<scope>.md` with the question and scope, Proposal
   Plan and Research Note paths, branch type, reproducible artifact path (or branch and commit),
   run instructions, scenarios exercised, verdict and rationale, unresolved
   questions, and confirmation source/date. For a skipped stage, save the scope
   and `not applicable` reason instead. Keep the referenced source available.
7. Update the plan's `Prototype Confirmation` with the note path, scope, accepted
   behavior, and confirmation source/date, or the `not applicable` reason.
   If prototype feedback changes stories, acceptance criteria, constraints,
   architecture, or the Change split, mark the section `pending` and return to
   `$tina-propose-plan` to reconcile and confirm the plan. Then revalidate the
   prototype against that plan before handing off to `$tina-propose-run`.

After confirmation, return the updated plan path, Prototype Note, and next prompt:

```text
/goal Execute $tina-propose-run docs/proposal-plan/<date>-<scenarios>.md.
Follow the success criteria and stopping condition in that file.
Do not grill, ask for individual confirmation, or archive.
```

## Lifecycle overrides

Upstream capture steps fold validated logic or the winning UI into real code.
Defer that work to authorized `$tina-apply` after proposal planning and review.
Keep the prototype as a reviewable source; a retained local artifact is sufficient
without an implementation issue or automatic branch commit. Do not delete the
only runnable copy during handoff. The Proposal Plan records the accepted
behavior; prototype code does not become a production specification or bypass
implementation checks.
