---
name: tina-propose-plan
description: Research, grill, align the domain model, apply the size gate, and confirm an ordered set of Tina changes. Write the confirmed split strategy to docs/proposal-plan/<date>-<scenarios>.md and give the user the next /goal prompt. Use for the planning and confirmation step only.
---

# Tina Propose Plan

This workflow authorizes planning only. Never implement, run the propose loop, or apply the Change.

1. Read applicable `CONTEXT-MAP.md` or `CONTEXT.md`, related ADRs, current
   OpenSpec specs, and the relevant code.
2. If an external or unstable fact is unresolved, invoke
   `$tina-research` first and read its resulting Research Note.
3. Invoke `$grill-with-docs` when behavior is new, terminology or boundaries are
   unclear, modules are crossed, or a hard-to-reverse decision is possible. In
   Codex, explicitly load and follow `$grilling` and `$domain-modeling` together:
   update glossary terms as they settle, create only qualifying ADRs, and wait
   until the user confirms shared understanding.
4. Apply the size gate before creating artifacts. One Change has one intent, no
   more than two capabilities, no more than about eight coarse tasks, and fits
   one focused implementation session. If it fails, return an ordered set of
   smaller Changes with dependencies and wait for confirmation. Do not create
   several Changes automatically.
5. Invoke `$openspec-propose`. The project default must resolve to the
   `tina` schema. Follow its dynamic instructions and preserve Domain
   Model vocabulary and ADR decisions.
6. Only if the user explicitly requested HTML visualization, invoke
   `$tina-change-visual` to generate `change.html` in the Change directory from
   `proposal.md` and `design.md` when present. Otherwise skip this step
   silently; do not ask.
7. Recheck the completed artifacts against the size gate. If they reveal excess
   scope, stop and recommend a split; never hide scope in oversized tasks.

When the user asks to plan a set of changes, stop after confirming the split and
do not create every Change's artifacts in this step. Write the confirmed plan to
`docs/proposal-plan/<date>-<scenarios>.md`, where `<date>` is the creation date
and `<scenarios>` is a short scenario name. The file must include:

- the outcome;
- the ordered Change list with dependencies and parallelizable items;
- each Change's single intent;
- the confirmed constraints;
- each Change's completion criteria and the overall stopping condition, designed
  from this planning session rather than copied from a fixed template.

End with the proposal-plan path, the next-step prompt below, and no automated
execution:

```text
/goal Execute $tina-propose-run docs/proposal-plan/<date>-<scenarios>.md.
Follow the success criteria and stopping condition in that file.
Do not grill, ask for individual confirmation, or archive.
```

For a single Change, still produce the normal OpenSpec artifacts and end with
`$openspec-apply-change` as the next explicit action.
