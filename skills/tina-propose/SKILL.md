---
name: tina-propose
description: Create a small, domain-aligned OpenSpec proposal after any needed research and grilling. Use whenever the user wants to plan, propose, specify, or prepare a change for implementation.
---

# Tina Propose

This workflow authorizes planning only. Never implement or apply the Change.

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
6. Recheck the completed artifacts against the size gate. If they reveal excess
   scope, stop and recommend a split; never hide scope in oversized tasks.

End with the Change path, artifacts created, domain references used, and the
next explicit action (`$openspec-apply-change`).
