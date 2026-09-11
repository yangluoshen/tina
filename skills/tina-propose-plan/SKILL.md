---
name: tina-propose-plan
description: Research, grill, align domain and architecture, and plan implementation Changes plus a separate QA Change from the original user stories. Save the confirmed strategy under docs/proposal-plan and provide the next goal prompt. Use for planning and confirmation only.
---

# Tina Propose Plan

This workflow authorizes planning only. Never implement, run the propose loop, or apply the Change.

At request-level planning, include a separate QA Change alongside the implementation
Changes, even when implementation needs only one Change. Use the confirmed-plan
path below. Mark each Change as `implementation` or `qa` in the plan and its
proposal's Scope. An assigned proposer creates only its assigned Change's artifacts
using the steps below; it must not create another plan or append another QA Change.

Design the QA Change from the original request's user stories and acceptance
criteria. Cover complete user journeys, cross-feature interactions, failure paths,
and observable outcomes. Its execution depends on all implementation Changes needed
by those stories, but its scenarios and tasks must not mirror their split. Record
the original request, story coverage, environment/data needs, and evidence required
for each scenario in proposal/tasks. Reference existing behavioral specs; a QA
Change without a product behavior delta uses `skip_specs: true` rather than
duplicating implementation specs. Keep design conditional. Apply the normal size
gate to QA work; if a split is needed, split by user journeys, retaining overall
story coverage, rather than creating one QA Change per implementation Change.

1. Read applicable `CONTEXT-MAP.md` or `CONTEXT.md`, related ADRs, current
   OpenSpec specs, and the relevant code.
2. If an external or unstable fact is unresolved, invoke
   `$tina-research` first and read its resulting Research Note.
3. Invoke `$grill-with-docs` when behavior is new, terminology or boundaries are
   unclear, modules are crossed, or a hard-to-reverse decision is possible. In
   Codex, explicitly load and follow `$grilling` and `$domain-modeling` together:
   update glossary terms as they settle, create only qualifying ADRs, and wait
   until the user confirms shared understanding.
4. Invoke `$tina-architecture`, which uses one independent `tina_architect`,
   before the size gate when the work crosses
   modules, services, processes, data stores, trust boundaries, ownership, or
   deployment topology; when the Change split depends on shared components or
   interfaces; or when the user requests target architecture. Wait until the user
   confirms the Architecture Model. Skip this step for a local behavior change
   that preserves existing boundaries.
5. Apply the size gate before creating artifacts. One Change has one intent, no
   more than two capabilities, no more than about eight coarse tasks, and fits
   one focused implementation or QA session. If it fails, return an ordered set of
   smaller Changes with dependencies and wait for confirmation. Do not create
   several Changes automatically.
6. Invoke `$openspec-propose`. The project default must resolve to the
   `tina` schema. Follow its dynamic instructions and preserve Domain
   Model vocabulary, ADR decisions, and confirmed Architecture Model when one
   exists.
7. Only if the user explicitly requested HTML visualization, invoke
   `$tina-change-visual` to generate `change.html` in the Change directory from
   `proposal.md` and `design.md` when present. Otherwise skip this step
   silently; do not ask.
8. Recheck the completed artifacts against the size gate. If they reveal excess
   scope, stop and recommend a split; never hide scope in oversized tasks.

When the user asks to plan a set of changes, stop after confirming the split and
do not create every Change's artifacts in this step. Write the confirmed plan to
`docs/proposal-plan/<date>-<scenarios>.md`, where `<date>` is the creation date
and `<scenarios>` is a short scenario name. The file must include:

- the original request, user stories, acceptance criteria, and outcome;
- the ordered Change list with dependencies and parallelizable items;
- each Change's type (`implementation` or `qa`) and single intent;
- the QA Change's story coverage and implementation prerequisites;
- the confirmed constraints;
- when architecture alignment ran, an `Architecture Alignment` section with the
  canonical JSON path, Archify `specification_sha256`, human confirmation, and
  each Change's component/connection stable IDs;
- each Change's completion criteria and the overall stopping condition, designed
  from this planning session rather than copied from a fixed template.

End with the proposal-plan path, the next-step prompt below, and no automated
execution:

```text
/goal Execute $tina-propose-run docs/proposal-plan/<date>-<scenarios>.md.
Follow the success criteria and stopping condition in that file.
Do not grill, ask for individual confirmation, or archive.
```

When creating one assigned Change's artifacts, return them to the parent for
proposal review. Implementation Changes execute through `$tina-apply`; QA Changes
execute through `$tina-qa` after their implementation prerequisites are ready.
