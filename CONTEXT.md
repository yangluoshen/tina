# Tina Workflow

A portable planning and coding workflow built around OpenSpec for use across personal projects.

## Language

**Workflow Bundle**:
A versioned collection of planning rules, agent skills, and installation material that can be applied to a target repository.
_Avoid_: Framework, plugin

**Change**:
One independently valuable intent tracked as a single OpenSpec change and sized for one focused implementation session.
_Avoid_: Epic, project

**Proposal**:
The OpenSpec artifact that establishes the motivation, scope, capability impact, and domain alignment of a Change.
_Avoid_: Plan, change

**Change View**:
A non-normative, diagram-led `change.html` derived from a Change's Proposal and optional design for faster human review.
_Avoid_: Proposal, specification, source of truth

**Domain Model**:
The canonical project vocabulary recorded in `CONTEXT.md` files, distinct from behavioral specifications and implementation design.
_Avoid_: Spec, architecture

**Research Note**:
A dated, cited account of external or unstable facts used as planning input rather than permanent project truth.
_Avoid_: ADR, specification

**Repository Instructions**:
Agent guidance that applies only while maintaining the Workflow Bundle's own repository.
_Avoid_: Target instructions, installed policy

**Target Instructions**:
Portable agent guidance installed into a repository that consumes the Workflow Bundle.
_Avoid_: Repository instructions, maintainer policy

**Upstream Snapshot**:
Byte-for-byte copies of selected dependency files from one exact upstream revision.
_Avoid_: Fork, local variant

**Dependency Pin**:
An exact upstream revision or release against which the Workflow Bundle has passed compatibility checks.
_Avoid_: Global installation, floating version
