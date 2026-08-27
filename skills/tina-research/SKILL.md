---
name: tina-research
description: Investigate external or unstable facts for planning, or inspect local code read-only, without using OpenSpec explore. Use for exploration, research, feasibility, and unfamiliar APIs or versions.
---

# Tina Research

Never invoke `openspec-explore`.

- For local repository facts, inspect the code, specs, CONTEXT files, and ADRs
  directly without creating an OpenSpec Change.
- For external, version-sensitive, or uncertain facts, invoke `$research` with
  one narrow question. Its report must use primary sources and land in the
  repository's existing research-note location.
- If already running as a subagent, perform the research directly; do not spawn
  another research agent.
- Treat a Research Note as dated input. Pass its path explicitly into the next
  grilling or propose step; never assume a later session will discover it.

Return the answer or report path and the decision it unblocks. Do not propose or
implement code unless the user separately requests that action.
