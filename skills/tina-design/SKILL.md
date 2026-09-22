---
name: tina-design
description: Use Impeccable to align UI direction, design Tina prototypes and production interfaces, and maintain the project's design language across proposal planning and implementation. Use for UI work, not backend-only changes or architecture diagrams.
---

# Tina Design

In DSH Tina Mode, first load `tina-dsh-runtime` and resolve resources against
the loaded skill's base directory. In Codex, use the installed skills below.

Load `$impeccable` and the reference relevant to the current stage. Apply these
Tina overrides to its setup, playbooks, and command output; keep upstream files
unchanged. Read the original request, Proposal Plan, existing `DESIGN.md` or
equivalent design-system documentation, related ADRs, and actual UI code/assets.
Reuse established product context from the plan, CONTEXT files, or `PRODUCT.md`;
do not repeat discovery or create a duplicate product brief just for setup.

## Planning and confirmation

During request-level `$tina-propose-plan`, use Impeccable's `reference/shape.md`
and the applicable visual-direction guidance in `reference/new-work.md`.
Confirm UI style and material details with the user before the Change split:
audience and primary task, brand/reference examples, visual character, hierarchy
and density, typography/color direction, key interactions and states, responsive
and accessibility constraints. Reuse settled answers and propose concrete choices
for the remaining decisions; do not make the user specify CSS values.

Preserve an existing visual identity unless redesign is in scope. Show a concise
direction for confirmation, with the prototype questions that remain. Record a
`UI Design` section in the Proposal Plan: scope, selected direction and constraints,
design-language document path, unresolved prototype questions, and confirmation
source/date. Keep page-specific decisions in the plan or Prototype Note.

In `$tina-yolo`, use the taste and judgment of a world-class UI designer to
choose a coherent direction suited to the product and its users. Do not ask
style questions or wait for upstream workshops, variant selection, or document
confirmation. Record assumptions, rationale, and `model-decided (tina-yolo)`.
Assigned agents inherit the parent's decisions and return conflicts to the
parent; they never repeat user discovery or independently change direction.

## Prototype and production work

For UI prototypes, combine `$prototype`'s UI branch with Impeccable's design
guidance. Read `reference/craft-floor.md` before editing UI. Build the bounded
question in the assigned isolated location using the plan's selected direction;
return the runnable artifact and proposed design-language updates to the parent.
The parent shows the result, aligns style and interaction with the user, and
records acceptance through `$tina-prototype` (model acceptance in YOLO).

During `$tina-propose-run`, translate the accepted design into the assigned UI
implementation Change's proposal, behavior specs when needed, and tasks. Include
affected surfaces, component/token reuse, interaction states, and responsive
behavior at the detail the implementation needs. Put shared design-system work
before dependent screens when the confirmed split calls for it. A local UI change
can stay in its existing implementation Change; do not add a standalone design
Change by default. If the design requires a different split, return to planning.

During authorized `$tina-apply`, read the linked design language and Prototype
Note, then use Impeccable's applicable design guidance and craft floor to build
the assigned production UI. The approved artifacts define scope. Resolve design
conflicts with the parent and update the design language when implemented choices
settle. Prototype code remains disposable; acceptance does not authorize copying
stub behavior into production.

## Durable design language

Use Impeccable's `reference/document.md` to create or update root `DESIGN.md`,
or the project's existing equivalent. The parent records confirmed shared choices
after planning and prototype acceptance; an implementer reconciles them with real
tokens/components after implementation. Merge only in-scope decisions and preserve
unrelated existing content. Label planned choices and prototype-derived values so
they are not represented as shipped components. Never extract rejected variants
into the canonical design language.

Capture reusable visual principles, color roles, typography, spacing/layout,
responsive rules, shape/depth, components and interaction/motion guidance where
relevant. Link actual token/component sources once implemented. Use the upstream
document format for a new file; preserve an established project's format. Keep
values authoritative in one place rather than copying token tables into Changes.
Link the plan, accepted Prototype Note, and related ADRs for rationale and history;
create an ADR only under the existing domain-modeling criteria. Routine visual
choices belong in the design language, not one ADR per styling decision.

`DESIGN.md` is project-level visual guidance. An OpenSpec Change's `design.md`
remains conditional technical design; UI work alone does not require that artifact
or a new schema stage. Cite the design-language path from the proposal and tasks,
and from technical design when present.

## Lifecycle overrides

The active Tina stage owns scope, confirmation, delegation, and handoff. Use
Impeccable's design and documentation guidance within that stage; do not start
its end-to-end craft pipeline, install hooks/live tooling, or spawn its finish
reviewer/documenter as an automatic side effect. Maintain design documents through
the existing parent/implementer ownership above, without extra documentation agents.
Run Impeccable-specific audit, critique, detectors, visual scoring, or polish/QA
loops only when the user explicitly requests them. Keep normal task verification,
prototype scenario exercise, and user style alignment; do not claim unrun checks.
