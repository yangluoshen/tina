---
name: tina-architecture
description: Create or update a validated system architecture model for human-agent alignment during tina-propose-plan. Use before the size gate when change boundaries depend on components, connections, trust boundaries, ownership, or deployment topology.
---

# Tina Architecture

This workflow authorizes architecture planning only. Never create OpenSpec Change
artifacts, implement code, or treat a rendered diagram as proof that the design is
correct.

1. Read applicable `CONTEXT-MAP.md` or `CONTEXT.md`, ADRs, Research Notes,
   existing Architecture Models, and the relevant code. Resolve any question that
   would change system boundaries or the Change split before continuing.
2. Choose one bounded scope. Derive a stable lowercase `[a-z0-9_]` slug and spawn
   one `tina_architect` as `<slug>_architect`, using the model and reasoning effort
   for `tina-architect` in the repository's `Tina Subagent Models` table. Send it
   the scope, source paths, relevant facts, canonical output path, and any existing
   stable IDs. Do not draw the model in the parent agent.
3. The architect must use `$archify` with diagram type `architecture`, create or
   update `docs/architecture/<scope>.architecture.json`, validate it, deliver
   temporary review HTML, and return its receipt and semantic IDs. When a tracked
   baseline exists, it also creates a temporary Architecture Delta. The JSON is the
   Architecture Model; generated artifacts are non-normative review projections.
4. Show the returned artifact to the user. Send focused feedback to the same
   `<slug>_architect`, then have it update, validate, and deliver again. Do not spawn
   a replacement architect during the review loop.
5. Wait for explicit human confirmation. Archify checks schema, evidence, layout,
   and artifact integrity; the user confirms architecture meaning and trade-offs.
6. Return the canonical JSON path, Archify `specification_sha256`, confirmed
   component/connection IDs, temporary review paths, and any safe deferred
   questions. Record qualifying decisions in ADRs and settled vocabulary in the
   Domain Model rather than duplicating their rationale in the JSON.

If the installed `$archify` skill or its CLI is missing, stop and report a broken
Tina installation. Do not silently replace the pinned dependency with another
diagram tool.
