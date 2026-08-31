# Tina 的 Codex Subagent 工作流集成方案

## 结论

把当前手工敲的长提示词变成 tina 的内置流程，不需要发明新的 agent 框架。Codex 已经有四项现成机制可以组合使用：项目级自定义 agent、skill、`AGENTS.md` 路由、`/goal` 长任务循环。方案不设统一入口，保留用户对 research、propose、apply 三个阶段的控制；复用现有 `$tina-research`，把现有 `$tina-propose` 改名 `$tina-propose-plan`，新增 `$tina-propose-run` 和 `$tina-apply`，再引入五个预设 subagent，把研究、变更设计、实施、真实环境 QA、代码 review 串成可重复的 loop，同时保持 tina 的 OpenSpec 权威源和「一个 Change 一个意图」约束。

参考的 OpenAI 官方文档：

- [Subagents](https://developers.openai.com/codex/subagents)：自定义 agent 的 TOML 位置、字段、模型继承和并发配置。
- [Build skills](https://learn.chatgpt.com/docs/build-skills)：skill 的 `name`/`description` 触发方式和 `.agents/skills` 发现规则。
- [Custom instructions with AGENTS.md](https://learn.chatgpt.com/docs/agent-configuration/agents-md)：指令链合并顺序与项目级路由。
- [Follow a goal](https://learn.chatgpt.com/use-cases/follow-goals)：`/goal` 的持续执行、验证循环和停止条件。
- [Hooks](https://learn.chatgpt.com/docs/hooks)：`SubagentStart`/`SubagentStop` 可用于按 agent 类型注入上下文或强制继续，但本方案 v1 不依赖它。

## 官方机制怎么支持这个需求

Codex 的项目级自定义 agent 是 `.codex/agents/` 下的独立 TOML 文件，每个文件定义一个 agent。必填字段只有 `name`、`description`、`developer_instructions`。父 agent 可以按 `name` 生成或点名 subagent，`description` 让 Codex 判断何时隐式选择它，`developer_instructions` 约束 subagent 的行为。可选配置包括 `model`、`model_reasoning_effort`、`sandbox_mode`、`mcp_servers`、`skills.config`；省略时从父会话继承。这正好覆盖 tina 需要的「propose / review / implement / QA」角色，而不必引入外部编排库。

skill 位于仓库 `.agents/skills/` 时会被 Codex 扫描，`SKILL.md` 的 `name` 和 `description` 只做渐进式发现，正文在选中后才加载。tina 现有的 `$tina-research` 已经是这种形式，`$tina-propose` 改名 `$tina-propose-plan` 后保持同一套安装方式；新增的 `$tina-propose-run` 和 `$tina-apply` 也沿用该方式。

`AGENTS.md` 在 Codex 启动时按「全局 → 项目根 → 当前目录」顺序合并，项目根文件可以持久地告诉 Codex：何时调用 `$tina-research`、`$tina-propose-plan`、`$tina-propose-run` 或 `$tina-apply`，哪个阶段允许 spawn 哪些 agent、在哪里写反馈和 concern。tina 已经把受管理区块追加到目标仓库根 `AGENTS.md`，路由规则可以直接放进同一区块。

`/goal` 适合跨多个 turn 的 loop。Phase 2 和 Phase 3 都有明确完成标志，因此分别映射为一个 goal；goal 的 stopping condition 来自 OpenSpec 产物和 review 结果，而不是模糊的「改完为止」。

Hooks 理论上可以用 `SubagentStop` 强制 review 不通过时继续跑 subagent，但 Codex 的原生父 agent 已经能用 follow-up task 驱动 loop。v1 不引入 hook，避免多一层信任确认和脚本维护；只有当后续发现 review 结果没有被稳定传递时才启用。

## 现状缺口

现有 tina 已能单条规划：`$tina-propose-plan` 生成 proposal、specs、design、tasks 和 `change.html`，`$tina-verify` 做静态验收，`$openspec-apply-change` 实施。它缺的是把多条 Change 和高层目标串成 loop 的入口，以及独立的 propose review、真实 QA 和 code review 角色。安装器目前只复制 `.agents/skills` 和 `openspec/schemas/tina`，还没有复制 `.codex/agents/`，也没有给目标仓库写入 `.codex` 预设。

## 设计原则

1. 不把 tina 变成通用 agent 框架。新增文件只服务两个阶段和五个角色。
2. OpenSpec 的 Markdown 继续是权威源；subagent 只产出、反馈、执行，不能改 schema 的边界。
3. 保持 tina 可移植。自定义 agent 不写死 `model`，当前 DeepSeek 配置下继承 `deepseek-v4-pro`，未来用户换成其他 provider 也无需改 bundle。
4. 写冲突与并行分开处理。propose/review 可以在不同 Change 间适度并行；apply 阶段必须按 Change 串行，并每个 Change 结束立即 commit，否则多个 implementer 同时改同一仓库会产生无法归因的 diff。
5. QA 只能报告问题，不能自己修；review 同样只反馈，不直接改实现。修复只发生在 implementer 身上。

## 新增文件

```text
tina/
├── skills/
│   ├── tina-apply/
│   │   └── SKILL.md
│   ├── tina-propose-plan/    # 由现有 tina-propose 改名
│   │   └── SKILL.md
│   └── tina-propose-run/
│       └── SKILL.md
├── agents/
│   ├── tina-proposer.toml
│   ├── tina-proposal-reviewer.toml
│   ├── tina-implementer.toml
│   ├── tina-qa.toml
│   └── tina-code-reviewer.toml
├── templates/AGENTS.md   # 修改：加入路由与 loop 约定
├── install.sh            # 修改：复制 agents/ 并保持冲突保护
└── test.sh               # 修改：验证 agents 安装与幂等性
```

`tina-researcher` 不新建。现有 `$tina-research` 已经是研究阶段入口，直接复用。研究输出继续落在目标仓库的 `docs/research/`。

## 预设 subagent

### `tina-proposer`

负责一次生成一个 Change 的完整 OpenSpec 规划，严格执行 `$tina-propose-plan` 的 size gate。父 agent 会在 Phase 2 里逐个 spawn 它。

```toml
name = "tina_proposer"
description = "Create one small, domain-aligned Tina OpenSpec proposal with proposal, specs, design when needed, tasks, and change.html. Use when a parent workflow assigns one change to plan."
developer_instructions = """
Follow the tina-propose-plan skill exactly.
Plan one intent, at most two capabilities, and no more than about eight coarse tasks.
If the change exceeds the size gate, return an ordered split instead of hiding scope.
Write narrative in Chinese by default, preserving identifiers, paths, code, and established terms.
Never implement, apply, or archive. End with the Change path, artifacts created, and review handoff.
"""
```

### `tina-proposal-reviewer`

独立审阅 proposal、specs、design、tasks，不回写文件。输出按严重度分级，供父 agent 回传给 proposer。

```toml
name = "tina_proposal_reviewer"
description = "Independently review a Tina OpenSpec proposal for scope, capability delta, domain alignment, testability, and size-gate compliance. Use after a proposer finishes, before implementation."
sandbox_mode = "read-only"
developer_instructions = """
Read proposal.md, all specs, design.md when present, tasks.md, change.html, and applicable CONTEXT/ADR files.
Do not modify files and do not implement.
Return one verdict: Approved or Needs changes.
For Needs changes, list concrete required edits with file paths and reasons. Separate Critical, Warning, and Suggestion.
Do not approve a proposal with unchecked tasks, missing capability delta, or hidden oversize scope.
"""
```

### `tina-implementer`

按 `tasks.md` 实施一个 Change，运行每个任务的验证，QA 或 review 返回问题后由它修复。不允许自动归档。

```toml
name = "tina_implementer"
description = "Implement one Tina OpenSpec change using openspec-apply-change, run each task's verification, and fix issues reported by QA or review. Use during the apply phase."
developer_instructions = """
Apply one change with $openspec-apply-change.
Implement one pending task at a time and run its stated verification before marking it complete.
When QA or review returns an issue, fix the root cause in this same change and re-run the relevant verification.
Do not archive, and do not start the next change until the parent asks.
"""
```

### `tina-qa`

在真实环境验收 Change，优先使用浏览器工具。产出 `docs/qa/<change>.md`，并把问题交给 implementer。

```toml
name = "tina_qa"
description = "Run real-environment acceptance QA for one implemented Tina change. Start required services, exercise the actual behavior through browser tools, and write issues to docs/qa/. Use after implementation."
developer_instructions = """
Resolve the change's requirements and scenarios from proposal.md and specs before testing.
Build or reuse the real environment required by the change. Read the change's CONTEXT, docs, and any QA instructions to find the services, ports, credentials, browser tools, and harness entrypoints; do not assume a default service or port.
Prefer $agent-browser or $playwright-cli; use $chrome:control-chrome when the parent provides that tool.
Record every issue in docs/qa/<change>.md as Critical, Warning, or Suggestion, with reproduction steps and evidence.
Never fix code. End with a verdict: QA passed or QA failed, plus the exact file path handed to the implementer.
If a required service, browser tool, or credential is unavailable, record it as a blocker; do not fake a pass.
"""
```

### `tina-code-reviewer`

QA 完成后做 code review，关注正确性、安全、行为回归、测试缺口和规格一致性，不回写文件。

```toml
name = "tina_code_reviewer"
description = "Review the final diff of one Tina change after QA for correctness, security, behavior regressions, missing tests, and spec/task alignment. Use after QA, before archive."
sandbox_mode = "read-only"
developer_instructions = """
Review the change's git diff, proposal, specs, tasks, and QA report together.
Do not modify files. Do not archive.
Return Approved or Needs changes.
For Needs changes, list required fixes with file paths, reasons, and reproduction steps. Prioritize correctness, security, and spec divergence over style.
"""
```

模型和 reasoning effort 不写进这些 TOML，因为 TOML 无法根据 Codex profile 做条件选择。角色定义和模型选择分开：TOML 只描述职责，具体模型矩阵放在 `$tina-propose-run` 和 `$tina-apply` 的编排指令里，由父 agent 在 spawn 时根据当前 profile 传入 `model` 和 `reasoning_effort`。

## 模型与 profile 区分

Codex 的 profile 是会话级配置层，不是 per-subagent 配置。按官方 [Advanced Configuration](https://learn.chatgpt.com/docs/config-file/config-advanced#profiles)，`--profile <name>` 会先加载 `~/.codex/config.toml`，再叠加 `~/.codex/<name>.config.toml`；profile 文件只能放顶层配置键，不能写 `[profiles.<name>]`。当前机器上的 `~/.codex/config.deepseek.toml` 只是通过 `--config` 或启动脚本加载的普通配置，不是标准 profile。要区分 profile，应迁移为：

```text
~/.codex/config.toml               # 共用默认值
~/.codex/deepseek.config.toml      # codex --profile deepseek
~/.codex/openai.config.toml        # codex --profile openai
```

自定义 agent 文件虽然可以设置 `model` 和 `model_reasoning_effort`，但这些值是静态的。若在 `tina-proposer.toml` 写 `model = "deepseek-v4-pro"`，切到 openai profile 时仍会用 DeepSeek。所以 tina 不采用「每 role 一个固定 TOML 模型」，而是把模型矩阵放进编排 skill：

| Subagent | deepseek profile | openai profile |
|---|---|---|
| `tina-implementer` | `deepseek-v4-flash`，`max` | `gpt-5.6-terra`，`max` |
| `tina-qa` | `deepseek-v4-flash-vision-exp`，`max` | `gpt-5.6-sol`，`medium` |
| `tina-proposer`、`tina-proposal-reviewer`、`tina-code-reviewer` | `deepseek-v4-pro`，`high` | `gpt-5.6-sol`，`high` |

父 agent 在 spawn 每个角色时读取当前 profile 或 `model_provider`，从表中取对应值。这依赖 Codex 的显式 spawn 覆盖能力：官方 subagents 文档说明，显式 spawn 值优先于 `[agents]` 默认值和父会话值。若当前运行环境没有显式 spawn 模型参数，就退化为在 `~/.codex/<name>.config.toml` 里设置 `[agents].default_subagent_model` 和 `default_subagent_reasoning_effort`，但那样只能设一个全局默认，无法覆盖五种角色的差异，所以显式 spawn 是首选。

当前 DeepSeek profile 的 [models.json](/home/yangluo/.codex/models.json) 只注册了 `deepseek-v4-flash` 和 `deepseek-v4-pro`，没有 `deepseek-v4-flash-vision-exp`。要启用 QA 的视觉模型，需要先在模型目录补一条 `input_modalities = ["text", "image"]`、`supported_reasoning_levels` 含 `max` 的条目。DeepSeek 官方文档显示该模型支持 Responses API 和图文输入，文本能力与 `deepseek-v4-flash` 持平（[V4-Flash-Vision-Exp 上线](https://api-docs.deepseek.com/zh-cn/news/news260821/)、[图像理解](https://api-docs.deepseek.com/zh-cn/guides/vision)）；但官方图像理解页没有单独列出它的 `reasoning_effort` 支持表。实施时应先做一次带真实截图的 QA 请求验证 `max`，若 API 明确拒绝 `max` 再报告，不能无声降级。

## 三个阶段入口

不设统一的 `tina-run`。三个阶段分别由用户发起，保持人工控制节奏。

### `$tina-research`

继续使用现有 `tina-research` skill，不新增 orchestration。用户需要调研时自行调用，结果落在 `docs/research/`，不自动进入 propose。

### `$tina-propose-plan`

由现有 `$tina-propose` 改名而来，只负责调研、grilling、领域对齐、size gate 和与用户确认拆分策略。它产出的是「已确认的、按依赖排序的 Change 列表」，并把拆分策略写入 Markdown，不是进入长时间 loop。这里允许并需要多轮用户 confirm。

拆分策略固定写到 `docs/proposal-plan/<date>-<scenarios>.md`，其中 `<date>` 是创建日期，`<scenarios>` 是简短场景名。文件按 Goal mode 的要求写，至少包含：目标（outcome）、按顺序排列的 Change 列表、每个 Change 的单一意图、依赖关系、可并行项、已确认的约束，以及根据本次拆分实际情况设计的每个 Change 完成标准和总体停止条件。成功标准不写死在模板里，由 `$tina-propose-plan` 在 grilling 和 confirm 之后具体设计。`$tina-propose-run` 只读取用户指定的这份文件，不重新解释目标。

`$tina-propose-plan` 在输出末尾还要给用户一条可直接复制的下一步提示：

```text
/goal Execute $tina-propose-run docs/proposal-plan/<date>-<scenarios>.md.
Follow the success criteria and stopping condition in that file.
Do not grill, ask for individual confirmation, or archive.
```

### `$tina-propose-run`

在 `$tina-propose-plan` 完成并确认 `docs/proposal-plan/<date>-<scenarios>.md` 后执行。它不 grilling、不再要求逐项 confirm，直接进入一个长时间 goal，按该文件里的顺序生成并 review 每个 Change。

关于 goal 触发：`/goal Execute $tina-propose-run docs/proposal-plan/<date>-<scenarios>.md` 可行，但成功标准来自 proposal-plan 文件，不由这段固定文本写死。官方 [Long-running work](https://learn.chatgpt.com/docs/long-running-work) 说 `/goal` 的 goal 文本同时是第一条 prompt 和完成标准，Codex 的 `$` 语法又用于显式调用 skill，所以 `$tina-propose-run` 应能被识别为第一条 prompt 的 skill 调用。`$tina-propose-plan` 生成的下一步提示会把目标文件作为唯一标准来源。

如果当前 Codex 会话暴露 goal 工具（例如 `create_goal`），`$tina-propose-run` 也可以让 Codex 调用它；否则保持用户显式 `/goal` 是更稳的 fallback。官方 [Slash commands](https://learn.chatgpt.com/docs/reference/slash-commands) 和 [Follow a goal](https://learn.chatgpt.com/use-cases/follow-goals) 都只把 `/goal` 定义为用户启动 Goal mode 的方式，未单独说明 `$skill` 组合，因此完整 goal 文本比只写 `$tina-propose-run` 更保险。

```markdown
When the confirmed docs/proposal-plan/<date>-<scenarios>.md exists:
1. Create or use the active goal. Take the objective and stopping condition
   from docs/proposal-plan/<date>-<scenarios>.md; do not invent them.
2. Read docs/proposal-plan/<date>-<scenarios>.md. Do not grill or ask the user to confirm
   individual changes; use the file as the source of truth.
3. For every spawn, choose the model and reasoning effort from the model matrix
   for the active profile.
4. For each change, spawn one `tina_proposer`, then spawn
   `tina_proposal_reviewer`. If the verdict is Needs changes, send the review
   back to the same proposer and repeat until Approved. Parallelize only when
   two changes do not touch the same capabilities or files.
5. Record each change's final review result in docs/run/<change>-plan.md.
6. Mark the goal complete only when all changes are Approved.
```

### `$tina-apply`

新增 `skills/tina-apply/SKILL.md`，对应 Phase 3。它只负责实施、真实 QA、代码 review 和逐 Change commit，不回到 propose。

```markdown
---
name: tina-apply
description: Implement approved Tina changes one at a time, run real-environment QA and code review, and commit each change before moving on. Use only after the user explicitly authorizes implementation.
---

# Tina Apply

Never run without an explicit authorizing request. Do not archive.

1. If no active goal exists, create one: implement the selected changes in
   dependency order, pass QA and review, and commit each change before moving on.
2. For each change in dependency order:
   a. Choose the active profile's model/reasoning pair for this spawn.
   b. Spawn `tina_implementer`.
   c. Spawn `tina_qa`; if QA failed, return its docs/qa/<change>.md to the
      implementer and repeat until passed.
   d. Spawn `tina_code_reviewer`; if Needs changes, return the review to the
      implementer and repeat until Approved.
   e. Verify the worktree contains only this change's expected files, then
      `git add` and commit with `tina(change): <change-name>`.
3. Write unresolved concerns and leftover questions to
   docs/run/<change>-concerns.md and summarize them for the user when the goal
   ends.
4. Leave archive and verify as separate user actions.
```

`$tina-propose-run` 和 `$tina-apply` 都依赖父 agent 具备的协作工具来 spawn、等待和 follow-up subagent。它们不定义新的子进程格式，也不要求 Codex hook。

## `templates/AGENTS.md` 路由改动

在现有 managed block 的 Routing 段追加：

```text
- Use `$tina-research <question>` for research; it is user-initiated and does
  not open a change.
- Use `$tina-propose-plan <change or goal>` to research, grill, size-gate, and
  confirm the ordered change list with the user; write the split to
  docs/proposal-plan/<date>-<scenarios>.md and do not start the loop.
- Start the propose loop with
  `/goal Execute $tina-propose-run docs/proposal-plan/<date>-<scenarios>.md.
  Follow the success criteria and stopping condition in that file.` The goal
  text carries both the skill invocation and the pointer to that file; it loops
  tina_proposer and tina_proposal_reviewer until the file's stopping condition
  is met.
- Use `$tina-apply <scope>` only after the user explicitly authorizes
  implementation; it drives tina_implementer, tina_qa, and tina_code_reviewer,
  commits each change, and does not archive.
```

同时保留原有单条命令，`$openspec-apply-change`、`$tina-verify` 仍可手工调用；`$tina-propose-run` 和 `$tina-apply` 只负责各自的多 Change loop。

## 安装器改动

`install.sh` 在现有 `tina-research`、`tina-change-visual`、`tina-verify` 之外，把 `tina-propose` 替换为 `tina-propose-plan`，并增加复制 `tina-propose-run` 和 `tina-apply`；再把源目录 `agents/` 复制到目标 `.codex/agents/`，保持现有的非破坏性冲突保护。

```sh
for agent in tina-proposer tina-proposal-reviewer tina-implementer tina-qa tina-code-reviewer; do
  check_directory "$WORKFLOW_ROOT/agents/$agent" "$TARGET_ROOT/.codex/agents/$agent"
done

# 与 skill 复制相同，采用 copy_directory
for agent in tina-proposer tina-proposal-reviewer tina-implementer tina-qa tina-code-reviewer; do
  copy_directory "$WORKFLOW_ROOT/agents/$agent" "$TARGET_ROOT/.codex/agents/$agent"
done
```

`copy_directory` 已能创建缺失的父目录，因此目标项目原本没有 `.codex/agents/` 也能安装。目标已有同名且内容不同的 agent 时，`check_directory` 会拒绝覆盖并显示 diff，和现有 skill 冲突行为一致。

`test.sh` 需要增加断言：目标项目存在 `tina-propose-plan`、`tina-propose-run`、`tina-apply` 三个 skill，五个 `.codex/agents/*.toml`，且每个 agent 文件包含必填的 `name`、`description`、`developer_instructions`；再次安装保持幂等；对已修改的 skill 或 agent 文件拒绝覆盖。

## Phase 到 tina 的映射

| 用户阶段 | 入口 | 主要 subagent | 产物 |
|---|---|---|---|
| Phase 1 研究 | `$tina-research <问题>` | 无，复用 `$tina-research` | `docs/research/*.md` |
| Phase 2 变更设计 | 确认：`$tina-propose-plan <目标>`；执行：`/goal` + `$tina-propose-run` | `tina_proposer`、`tina_proposal_reviewer` | `docs/proposal-plan/<date>-<scenarios>.md`、每个 Change 的 `proposal.md`、`specs/`、`design.md`、`tasks.md`、`change.html`、`docs/run/<change>-plan.md` |
| Phase 3 实施 | `/goal` + `$tina-apply <范围>` | `tina_implementer`、`tina_qa`、`tina_code_reviewer` | 每个 Change 的 commit、`docs/qa/<change>.md`、`docs/run/<change>-concerns.md` |

Phase 2 拆成两步：`$tina-propose-plan` 负责 grilling 和用户确认拆分，并把结果写入 `docs/proposal-plan/<date>-<scenarios>.md`；`$tina-propose-run` 只读该文件执行 loop。执行 loop 在单个 Change 内串行：proposer 出稿，reviewer 审，失败则把反馈回传 proposer，直到通过。不同 Change 可以在没有文件冲突时并行出稿。

Phase 3 的 loop 也是单个 Change 内串行：implementer 实施，qa 验收并写问题文件，reviewer 复审，失败反馈给 implementer；一个 Change 通过后立即 commit，再进入下一个 Change。这样每个 commit 都能独立回滚和 diff。

## 完成标志与人工闸门

- Phase 2 完成：变更列表完整，每个 Change 都有 Approved 的 proposal、specs、tasks、design/跳过说明和 `change.html`，plan 日志存在。
- Phase 3 完成：目标范围内每个 Change 都有 QA passed、review Approved 和一个 commit，工作树干净，concerns 已写盘。
- 仍保留的人工闸门：Phase 2 的拆分和 confirm 在 `$tina-propose-plan` 阶段完成，`$tina-propose-run` 不再逐项询问；Phase 3 必须先由用户明确授权；archive 仍单独请求。QA 和 review 永远不自动归档。

## 不做什么

- 不新增 OpenSpec schema 字段或依赖。subagent 只消费现有 proposal/specs/tasks 结构。
- 不引入 hook、新插件或 MCP 服务。先验证父 agent 的 follow-up loop 是否稳定。
- 不写死模型、端口或本地机器路径。浏览器工具、服务端口和 harness 入口属于目标仓库或用户环境，由 `$tina-apply` 的请求参数、目标 `AGENTS.md` 或 `CONTEXT.md` 提供。
- 不改 vendored Matt Pocock skill。所有编排策略留在 `tina-propose-run`、`tina-apply`、`agents/` 和 Target Instructions。

## 需要确认的风险

并行 propose/review 时，多个 Change 可能引用同一份尚在变化的规格。方案要求父 agent 只在文件不重叠时并行，否则串行；实现后在 `$tina-propose-run` 中检查两个 Change 是否声明同一 capability，若重叠则串行。

QA 的真实环境可能缺少浏览器工具、凭证或 harness。预设 QA agent 会把缺环境记为 blocker，而不是降级成静态验收。若用户希望无浏览器时自动跳过 QA，需要在 `$tina-apply` 请求中显式说明，否则默认失败。

如果 Codex 原生 subagent 的 follow-up 循环不稳定，再启用 `SubagentStop` hook 作为补充；v1 不提前加入。
