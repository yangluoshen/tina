---
name: tina-change-visual
description: Generate or refresh a Tina Change's change.html as a diagram-led Chinese decision brief derived only from proposal.md and optional design.md. Use after Tina proposal planning or when those sources change, not for general diagrams or non-HTML export.
license: MIT
---

# Tina Change Visual

Create `change.html` beside `proposal.md`. This is a non-normative review
projection for humans; `proposal.md` and `design.md` remain authoritative.

## Sources

Read `proposal.md` fully and `design.md` when it exists. Extract only their
intent, why, scope and non-goals, affected capabilities or systems, decisions,
alternatives, risks, and impact. Preserve identifiers, paths, code, and
established terms. Never invent a requirement, decision, architecture, or fact.
If the sources conflict, stop and fix the Markdown instead of choosing in HTML.

Start from this skill's `assets/change.html` template.

## Diagram selection

Choose the one question a human must answer fastest, then select one primary
software diagram. Architecture is the default when no narrower type fits.

| Show | Type |
|---|---|
| Modules, boundaries, integration, or control/data movement | Architecture |
| Branching rules or algorithms | Flowchart |
| Time-ordered API, event, or component interaction | Sequence |
| Lifecycle states, guards, and transitions | State machine |
| Conceptual entities, relationships, and cardinality | ER / data model |
| Abstraction, execution, or enforcement layers | Layer stack |
| Zones, hosts, artifacts, replicas, or ports | Deployment |
| Module, package, or service fan-in and cycles | Dependency graph |
| Operations, inheritance, or composition | UML class |
| Physical tables, SQL types, constraints, indexes, and FKs | Database schema |

Use UML class, database schema, or deployment only when that detail is itself a
decision. Add a second diagram only when `design.md` contains another independent
decision axis that would make the primary diagram unreadable.

## Output

- Write one responsive, static `change.html` with Chinese narrative.
- Keep CSS and SVG inline. Use system fonts. Do not add JavaScript, remote
  resources, images, animation, imports, exports, themes, or configuration.
- Lead with a one-sentence thesis and the primary diagram. Limit remaining prose
  to short scope, non-goal, decision, risk, and impact annotations.
- If `design.md` is absent, derive only intent, scope, capabilities, and impact
  from the proposal and say that no design artifact was needed.
- Link back to the Markdown sources and state that they are authoritative. Link
  to `design.md` only when it exists.

## Diagram rules

Target 5–7 nodes; never exceed 9 nodes, 12 connectors, or 2 accent elements per
diagram. When over budget, remove decoration, merge duplicates, collapse leaf
detail, remove side paths that do not change the story, then split once if still
necessary. Never shrink text to hide excess content.

Use a 4px grid. Draw connectors before nodes. Off-axis connections use rounded
orthogonal paths, never diagonals. Do not overlap connectors or route through
non-endpoint nodes. Fan multiple connections on one edge to distinct attachment
points at least 12px apart. Put each connector label on an opaque mask with a
6–10px gap from its line.

Every meaningful SVG uses `role="img"` and `aria-labelledby`. Its first child is
a non-empty `<title>`, followed by a non-empty `<desc>`; both IDs are unique and
prefixed for that diagram. The page must remain understandable at 320px width
through horizontal diagram scrolling, and Chinese labels must not clip.

Before finishing, remove every node, connector, label, and card that does not
change the decision. Confirm the HTML contains no exclusive fact, script, remote
URL, inaccessible SVG, overlapping connector, or unreplaced placeholder.

Adapted from Cathryn Lavery's `diagram-design` under the included MIT license.
