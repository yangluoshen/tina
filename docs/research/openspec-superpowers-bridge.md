# `superpowers-bridge`：用 Superpowers 构建 OpenSpec 工作流的最佳实践案例

> 研究快照：2026-08-27。核心样本为 `JiangWay/openspec-schemas` 提交 [`f5d40404856ad0f4ce9eb482cbb0e28cf434411f`](https://github.com/JiangWay/openspec-schemas/tree/f5d40404856ad0f4ce9eb482cbb0e28cf434411f)，本地路径 `tmp/openspec-schemas/`；OpenSpec 官方实现为 `v1.11.0`、提交 [`a0ddb60d040c61f4907436a9d91310934b1dda63`](https://github.com/Fission-AI/OpenSpec/tree/a0ddb60d040c61f4907436a9d91310934b1dda63)，本地路径 `tmp/OpenSpec/`；Superpowers 同时核对 bridge 声明的 `v5.1.0` 提交 [`f2cbfbefebbfef77321e4c9abc9e949826bea9d7`](https://github.com/obra/superpowers/tree/f2cbfbefebbfef77321e4c9abc9e949826bea9d7) 与当前 `v6.3.0` 提交 [`b36e0829c6d0140e93cfef2ca599b1b07d4a7797`](https://github.com/obra/superpowers/tree/b36e0829c6d0140e93cfef2ca599b1b07d4a7797)。只使用上述官方/第一方仓库、源码、CI 和 issue。

## 结论先行

1. `superpowers-bridge` 的核心设计是对的：**OpenSpec 管“要交付什么”与 artifact 生命周期，Superpowers 管“如何设计和执行”**；bridge 不修改两边源码，只通过项目级 custom schema 的 `instruction` 调用技能、重定向产出并编排工作流。[bridge 定位](https://github.com/JiangWay/openspec-schemas/blob/f5d40404856ad0f4ce9eb482cbb0e28cf434411f/superpowers-bridge/README.md#L1-L12)（本地 `superpowers-bridge/README.md:1-12`）
2. 最值得复制的不是它的全部提示词，而是四个模式：**单一 change 目录、粗任务与微计划分层、能力 PRECHECK、实现后 evidence artifact**。这四点能减少 OpenSpec/Superpowers 的重复文件与手工切换。
3. 这份 bundle **不是当前版本下可无条件生产采用的成品**。它固定的行为背书仍是 OpenSpec `1.4.1` + Superpowers `v5.1.0`；公开 drift issue 截至 2026-08-24 仍为 open，最新机器人记录是 OpenSpec `1.10.0`、Superpowers `v6.3.0`，只证明 schema structure validate 通过，不是端到端行为背书。[兼容矩阵](https://github.com/JiangWay/openspec-schemas/blob/f5d40404856ad0f4ce9eb482cbb0e28cf434411f/superpowers-bridge/README.md#L466-L505) · [最新 drift 记录](https://github.com/JiangWay/openspec-schemas/issues/13#issuecomment-5396871204)
4. 对 Codex 不能照抄 README 的 Claude 命令。当前 OpenSpec 对 Codex 是 skills-only，调用形式是 `$openspec-*`；Superpowers 应从 Codex 官方插件市场安装，而不是运行 `claude plugin install`。[OpenSpec 工具矩阵](https://github.com/Fission-AI/OpenSpec/blob/a0ddb60d040c61f4907436a9d91310934b1dda63/docs/supported-tools.md#L1-L41)（本地 `tmp/OpenSpec/docs/supported-tools.md:1-41`）· [Superpowers Codex 安装](https://github.com/obra/superpowers/blob/b36e0829c6d0140e93cfef2ca599b1b07d4a7797/README.md#L92-L116)
5. 本地用 OpenSpec `1.11.0` 实测：`schema validate`、schema 列表、创建 change、状态 DAG、apply instructions、strict change validation 与 archive 均可运行；但实测也确认 `verify` 在 `plan.md` 一出现就被图标为 `ready`，且缺 `## Purpose` 的新 capability 归档后留下 `TBD`，随后 strict validation 以 warning 判失败。也就是说：**结构兼容成立，行为与内容质量仍需人/agent gate。**

## 一、它到底解决什么问题

OpenSpec 原生 schema 负责 artifact、模板、依赖与 apply 入口；Superpowers 原生工作流负责 brainstorming、worktree、微计划、TDD、review 与分支收尾。直接混用会出现三类重复：brainstorming 默认把设计写到 `docs/superpowers/specs/`，OpenSpec 又写 proposal/design；OpenSpec 的粗粒度 `tasks.md` 与 Superpowers 的微步骤 plan 分散在不同位置；用户还得记住每一步调用哪个技能。bridge README 对这三个问题有明确陈述。[问题定义](https://github.com/JiangWay/openspec-schemas/blob/f5d40404856ad0f4ce9eb482cbb0e28cf434411f/superpowers-bridge/README.md#L121-L136)（本地 `superpowers-bridge/README.md:121-136`）

它选择 custom schema 而不是修改 OpenSpec/Superpowers 本体，符合 OpenSpec 的扩展契约：项目级 schema 放在 `openspec/schemas/<name>/`，随项目版本控制；社区 schema 也应由独立仓库发布，再把 bundle 复制到项目内。[OpenSpec custom schema](https://github.com/Fission-AI/OpenSpec/blob/a0ddb60d040c61f4907436a9d91310934b1dda63/docs/customization.md#L163-L177) · [community schema 分发](https://github.com/Fission-AI/OpenSpec/blob/a0ddb60d040c61f4907436a9d91310934b1dda63/docs/customization.md#L413-L417)

可以把责任边界概括为：

```text
需求与验收合同                    实施纪律
OpenSpec                          Superpowers
proposal / delta specs            brainstorming
design / tasks / status            writing-plans
validate / sync / archive          worktree / SDD / review / finish
              \                    /
               superpowers-bridge
         （schema DAG + prompt injection）
```

## 二、Schema DAG、artifact、template 与 instruction

### 2.1 实际 DAG

`schema.yaml` 声明 8 个 artifact：

```text
brainstorm ──┬──→ proposal ──→ specs ──┐
             │                         ├──→ tasks ──→ plan ──→ verify ──→ retrospective
             └──→ design ──────────────┘

apply.requires = [plan]
apply.tracks   = tasks.md
```

这不是一条简单串行链：`proposal` 与 `design` 在 `brainstorm` 后可并行 ready；`tasks` 同时依赖 `specs` 和 `design`；apply 只要求 `plan` 存在并从 `tasks.md` 解析进度。[完整 schema](https://github.com/JiangWay/openspec-schemas/blob/f5d40404856ad0f4ce9eb482cbb0e28cf434411f/superpowers-bridge/schema.yaml#L22-L195) · [apply 定义](https://github.com/JiangWay/openspec-schemas/blob/f5d40404856ad0f4ce9eb482cbb0e28cf434411f/superpowers-bridge/schema.yaml#L460-L567)（本地 `superpowers-bridge/schema.yaml:22-567`）

OpenSpec 的图引擎只按 `generates` 对应文件是否存在判断完成；`requires` 只决定 ready/blocked，多个 ready artifact 按声明顺序排序。[完成检测源码](https://github.com/Fission-AI/OpenSpec/blob/a0ddb60d040c61f4907436a9d91310934b1dda63/src/core/artifact-graph/state.ts#L6-L36) · [ready 计算源码](https://github.com/Fission-AI/OpenSpec/blob/a0ddb60d040c61f4907436a9d91310934b1dda63/src/core/artifact-graph/graph.ts#L141-L172)（本地 `tmp/OpenSpec/src/core/artifact-graph/state.ts:6-36`、`graph.ts:141-172`）

### 2.2 每个 artifact 的职责

| Artifact | 输入 / `requires` | 输出 | bridge 的职责划分 |
|---|---|---|---|
| `brainstorm` | 无 | `brainstorm.md` | 调用 `superpowers:brainstorming`，保存原始探索/决策过程，不先填 design。 |
| `proposal` | brainstorm | `proposal.md` | 从已批准的 brainstorm 提炼 why、范围、capability 与影响，不重新发散。 |
| `design` | brainstorm | `design.md` | 把 raw capture 重组为 Context、Goals、Decisions、Risks、Migration、Open Questions。 |
| `specs` | proposal | `specs/**/*.md` | 每个 capability 一个 delta spec，写可观察、可测试的 WHAT。 |
| `tasks` | specs + design | `tasks.md` | 粗粒度、可跟踪的 checkbox；由 OpenSpec apply 统计。 |
| `plan` | tasks | `plan.md` | 调用 `superpowers:writing-plans`，把粗任务展开成带路径、代码、测试、commit 的 2–5 分钟微步骤。 |
| `verify` | plan（图） | `verify.md` | 实际应在 apply 后运行，记录结构验证、任务、spec sync、设计一致性、git 信号与 coverage gap。 |
| `retrospective` | verify | `retrospective.md` | verify 不失败后，记录量化证据、wins/misses、偏差、skill compliance 与可推广学习。 |

上述职责直接来自 artifact instructions。[brainstorm/proposal/design/specs](https://github.com/JiangWay/openspec-schemas/blob/f5d40404856ad0f4ce9eb482cbb0e28cf434411f/superpowers-bridge/schema.yaml#L23-L142) · [tasks/plan](https://github.com/JiangWay/openspec-schemas/blob/f5d40404856ad0f4ce9eb482cbb0e28cf434411f/superpowers-bridge/schema.yaml#L144-L195) · [verify](https://github.com/JiangWay/openspec-schemas/blob/f5d40404856ad0f4ce9eb482cbb0e28cf434411f/superpowers-bridge/schema.yaml#L196-L302) · [retro](https://github.com/JiangWay/openspec-schemas/blob/f5d40404856ad0f4ce9eb482cbb0e28cf434411f/superpowers-bridge/schema.yaml#L304-L458)

### 2.3 template 与 instruction 应怎样配合

这个案例正确地把两者分开：

- `template` 给输出骨架和稳定格式，例如 `proposal.md` 的四个 section、`tasks.md` 的 checkbox、`verify.md` 的 7 类检查。
- `instruction` 给生成语义、读哪些依赖、何时调用外部 skill、失败时如何停止。
- `brainstorm.md` 特意只有注释，因为它是 raw capture；`design.md` 才是结构化 single source of truth。[brainstorm 模板](https://github.com/JiangWay/openspec-schemas/blob/f5d40404856ad0f4ce9eb482cbb0e28cf434411f/superpowers-bridge/templates/brainstorm.md#L1-L12) · [design 模板](https://github.com/JiangWay/openspec-schemas/blob/f5d40404856ad0f4ce9eb482cbb0e28cf434411f/superpowers-bridge/templates/design.md#L1-L49)

这符合 OpenSpec 官方契约：template 会注入 artifact prompt，适合放标题、HTML 注释与示例格式；instruction 定义 AI 该如何创建 artifact。[官方 template 说明](https://github.com/Fission-AI/OpenSpec/blob/a0ddb60d040c61f4907436a9d91310934b1dda63/docs/customization.md#L218-L295)

### 2.4 OpenSpec 与 Superpowers 的衔接点

bridge 有 7 个 Superpowers touchpoint：brainstorming、writing-plans、using-git-worktrees、subagent-driven-development、test-driven-development、requesting-code-review、finishing-a-development-branch；另有 OpenSpec 自己的 verify skill。[touchpoint 表](https://github.com/JiangWay/openspec-schemas/blob/f5d40404856ad0f4ce9eb482cbb0e28cf434411f/superpowers-bridge/README.md#L296-L310)

关键衔接方式有三种：

1. **输出重定向**：Superpowers `v5.1.0` brainstorming 默认写 `docs/superpowers/specs/...`，writing-plans 默认写 `docs/superpowers/plans/...`；两者都允许用户偏好覆盖默认路径。bridge 利用该契约，把输出改到当前 change 的 `brainstorm.md` 与 `plan.md`。[brainstorm 默认/覆盖](https://github.com/obra/superpowers/blob/f2cbfbefebbfef77321e4c9abc9e949826bea9d7/skills/brainstorming/SKILL.md#L107-L136) · [plan 默认/覆盖](https://github.com/obra/superpowers/blob/f2cbfbefebbfef77321e4c9abc9e949826bea9d7/skills/writing-plans/SKILL.md#L14-L20)
2. **双层计划**：`tasks.md` 是总体进度，`plan.md` 是 executor 输入。apply 因此 `requires: [plan]`、但 `tracks: tasks.md`；这是很值得复用的“粗追踪、细执行”模式。[bridge 解释](https://github.com/JiangWay/openspec-schemas/blob/f5d40404856ad0f4ce9eb482cbb0e28cf434411f/superpowers-bridge/README.md#L518-L525)
3. **能力与证据 PRECHECK**：调用 skill 前先确认名称可用；verify/retro 再用 git commit、已完成 task、verify 文件与 verdict 做运行时证据检查。它们不能变成引擎级 gate，但比只写“请在 apply 后执行”更可审计。[skill PRECHECK](https://github.com/JiangWay/openspec-schemas/blob/f5d40404856ad0f4ce9eb482cbb0e28cf434411f/superpowers-bridge/schema.yaml#L27-L57) · [evidence PRECHECK](https://github.com/JiangWay/openspec-schemas/blob/f5d40404856ad0f4ce9eb482cbb0e28cf434411f/superpowers-bridge/schema.yaml#L201-L223)

## 三、安装与启用：Codex 的正确做法

bridge README 的安装 prompt 是 Claude-first：检查 `CLAUDE.md`、运行 `claude plugin list/install`，日常命令也写成 `/opsx:*`。[bridge 安装文档](https://github.com/JiangWay/openspec-schemas/blob/f5d40404856ad0f4ce9eb482cbb0e28cf434411f/superpowers-bridge/README.md#L16-L51)（本地 `superpowers-bridge/README.md:16-51`）。Codex 应采用下面的等价流程。

### 3.1 安装 OpenSpec 与 Codex skills

```bash
npm install -g @fission-ai/openspec@1.11.0
cd your-project
openspec init --tools codex
```

OpenSpec 当前会把 Codex skills 写到 `.agents/skills/openspec-*/SKILL.md`，不会生成 Codex command prompt；调用形式是 `$openspec-<skill>`。[官方说明](https://github.com/Fission-AI/OpenSpec/blob/a0ddb60d040c61f4907436a9d91310934b1dda63/docs/supported-tools.md#L7-L22) · [Codex 行](https://github.com/Fission-AI/OpenSpec/blob/a0ddb60d040c61f4907436a9d91310934b1dda63/docs/supported-tools.md#L63-L77)

bridge 依赖 `verify`，而 `verify/new/continue/ff` 不在默认 core profile。若要复刻它的逐 artifact 流程，运行交互式 profile 配置，至少保留 `propose/apply/archive` 并加入 `new/continue/verify`，然后刷新项目 skills：

```bash
openspec config profile
openspec update
```

[profile 官方说明](https://github.com/Fission-AI/OpenSpec/blob/a0ddb60d040c61f4907436a9d91310934b1dda63/docs/workflows.md#L100-L152) · [生成的 skill 名称](https://github.com/Fission-AI/OpenSpec/blob/a0ddb60d040c61f4907436a9d91310934b1dda63/docs/supported-tools.md#L219-L239)

### 3.2 安装 Superpowers

在 Codex App 侧栏 Plugins 中安装 `Superpowers`，或在 Codex CLI 输入 `/plugins`，搜索 `superpowers` 后选择安装。两者都是 Superpowers 官方 README 当前给出的 Codex 安装路径。[官方安装](https://github.com/obra/superpowers/blob/b36e0829c6d0140e93cfef2ca599b1b07d4a7797/README.md#L92-L116)

生产使用不要把“已安装”当“已兼容”：bridge 的行为背书是 `v5.1.0`，市场当前版本是 `v6.3.0`。应记录实际插件版本/commit，并先跑本文后面的 dogfood gate。

### 3.3 安装 schema bundle

```bash
git clone https://github.com/JiangWay/openspec-schemas /tmp/openspec-schemas
mkdir -p openspec/schemas
cp -R /tmp/openspec-schemas/superpowers-bridge openspec/schemas/superpowers-bridge
openspec schema validate superpowers-bridge --verbose
openspec schemas
openspec schema which superpowers-bridge
```

然后可把它设为项目默认：

```yaml
# openspec/config.yaml
schema: superpowers-bridge
```

也可以不设默认，只在复杂 change 中明确指定。OpenSpec 的 schema 解析顺序是 CLI flag → change metadata → project config → `spec-driven`。[解析顺序](https://github.com/Fission-AI/OpenSpec/blob/a0ddb60d040c61f4907436a9d91310934b1dda63/docs/customization.md#L152-L160)

不要把仓库附带的 `CLAUDE.md.fragment.md` 原样塞进 Codex 项目；它的路由对象和命令都是 Claude。Codex 若需固定路由，应人工改写为项目 `AGENTS.md`，使用 `$openspec-*`，并保留“何时开 change、何时直接 PR”的风险分流原则。[Claude fragment](https://github.com/JiangWay/openspec-schemas/blob/f5d40404856ad0f4ce9eb482cbb0e28cf434411f/superpowers-bridge/templates/adopters/CLAUDE.md.fragment.md#L1-L46)

## 四、可复制案例：从需求到 archive

下面以“为订单创建接口增加幂等键，避免重试导致重复订单”为例。它改变对外 API 行为并增加新 capability，适合 bridge；纯 typo、文档或不改变行为合同的小修复不值得走整套流程。

### 4.1 入口与 change 创建

对 Codex 输入：

```text
$openspec-new-change add-order-idempotency
使用 superpowers-bridge。目标：客户端用 Idempotency-Key 重试创建订单时，
相同 key + 相同请求必须返回同一订单；相同 key + 不同请求必须拒绝。
```

如果 schema 已设为默认，可省略第二句；否则应明确说“使用 `superpowers-bridge`”，让 skill 调 `openspec new change ... --schema superpowers-bridge`。OpenSpec 官方 propose/new skill 会读取 `status --json` 和每个 artifact 的动态 instructions，不应自行假定默认 schema 的文件集。[propose skill 的 schema 选择](https://github.com/Fission-AI/OpenSpec/blob/a0ddb60d040c61f4907436a9d91310934b1dda63/skills/openspec-propose/SKILL.md#L42-L87)

### 4.2 一步一审地生成 planning artifacts

连续调用 `$openspec-continue-change add-order-idempotency`，但在每个用户审批点停下来：

```text
openspec/changes/add-order-idempotency/
├── .openspec.yaml                  schema: superpowers-bridge
├── brainstorm.md                   原始问题、备选方案、用户批准
├── proposal.md                     Why / What / Capabilities / Impact
├── design.md                       Context / Decisions / Risks / Migration
├── specs/
│   └── order-idempotency/spec.md   可观察合同与 scenarios
├── tasks.md                        粗粒度实现/验证 checklist
└── plan.md                         TDD 微步骤、路径、命令、commit 点
```

建议的人工 gate：

1. `brainstorm.md`：至少比较存储在订单表、独立幂等表、缓存三种路线；明确 TTL、并发、payload hash、失败重试语义。
2. `proposal.md`：New Capability 必须是 `order-idempotency`，不要混入“顺便重构订单服务”。
3. `spec.md`：至少覆盖首次创建、同 key 同 payload 重放、同 key 不同 payload 冲突、并发重复请求、过期策略与下游失败。
4. `design.md`：每个重要选择写 rejected alternative；没有 owner/影响面的 blocking question 不得留到 tasks。
5. `tasks.md`：每一项在 checkbox 描述里写验证方式；`plan.md` 的每个实现任务必须包含 RED、确认失败、GREEN、确认通过、commit。

`brainstorm → proposal/design → specs → tasks → plan` 的依赖来自 bridge schema；Superpowers `v5.1.0` writing-plans 要求 exact path、完整代码、确切命令、TDD 与频繁提交。[bridge DAG](https://github.com/JiangWay/openspec-schemas/blob/f5d40404856ad0f4ce9eb482cbb0e28cf434411f/superpowers-bridge/schema.yaml#L22-L195) · [writing-plans](https://github.com/obra/superpowers/blob/f2cbfbefebbfef77321e4c9abc9e949826bea9d7/skills/writing-plans/SKILL.md#L36-L120)

规划完成后做一次确定性检查：

```bash
openspec status --change add-order-idempotency --json
openspec validate add-order-idempotency --type change --strict --json
```

### 4.3 Apply：显式要求遵守 schema instruction

对 Codex 输入：

```text
$openspec-apply-change add-order-idempotency
以 `openspec instructions apply --change add-order-idempotency --json` 返回的
superpowers-bridge instruction 为准：先检查技能和工具，再建隔离 worktree，
用 superpowers:subagent-driven-development 执行 plan；每个 task 必须附 RED/GREEN
证据并完成 review，完成后更新 tasks.md。不要退化成通用手工 task loop。
```

预期执行链：

```text
skill/tool PRECHECK
  → using-git-worktrees + clean baseline
  → subagent-driven-development
      → fresh implementer
      → TDD evidence（必须在 task/dispatch 中显式要求）
      → per-task review
      → final whole-change review
  → tasks.md 全部 [x]
```

这里把 TDD 写进 task 与 subagent dispatch，而不只依赖“传递激活”。原因是当前 Superpowers `v6.3.0` 的 SDD 主 skill 已不出现 `test-driven-development` 引用，implementer template 只要求“如果 task 要求 TDD 才遵守”；review 仍是明确流程。[当前 SDD](https://github.com/obra/superpowers/blob/b36e0829c6d0140e93cfef2ca599b1b07d4a7797/skills/subagent-driven-development/SKILL.md#L1-L17) · [当前 implementer prompt](https://github.com/obra/superpowers/blob/b36e0829c6d0140e93cfef2ca599b1b07d4a7797/skills/subagent-driven-development/implementer-prompt.md#L29-L39)

### 4.4 Verify、retrospective 与 archive

bridge 的 schema instruction 想让 apply 一口气完成 verify → retro → archive → finishing；README 的 quick flow 却把它们写成独立命令。当前最稳的做法是：**先检查 apply 实际停在哪里，再只补未完成的动作，绝不重复 archive。**

```bash
openspec status --change add-order-idempotency --json
```

如果 `verify.md` 还不存在：

```text
$openspec-continue-change add-order-idempotency
```

continue 应读取 verify artifact instruction，执行 commit/task PRECHECK，并调用 `$openspec-verify-change` 的语义，把结果落到 `verify.md`。修完 blocking item 后重跑，直到 PASS/PASS WITH WARNINGS。随后再一次 `$openspec-continue-change` 生成 `retrospective.md`。

归档前保留三个真实 gate：

```bash
# 1. OpenSpec 内容
openspec validate --all --strict --json

# 2. 项目测试（按项目替换）
npm test

# 3. 任务和工作区
rg '^- \[ \]' openspec/changes/add-order-idempotency/tasks.md
git status --short
```

确认 spec 中没有新 capability 的 `TBD Purpose`、tasks 全完成、测试绿、verify 非 FAIL、retro 已写，再归档：

```text
$openspec-archive-change add-order-idempotency
```

或用静态 CLI：

```bash
openspec archive add-order-idempotency -y
```

最终文件流应为：

```text
openspec/specs/order-idempotency/spec.md
openspec/changes/archive/YYYY-MM-DD-add-order-idempotency/
├── brainstorm.md
├── proposal.md
├── design.md
├── specs/order-idempotency/spec.md
├── tasks.md
├── plan.md
├── verify.md
└── retrospective.md
```

最后才运行 `superpowers:finishing-a-development-branch`，让用户选择本地 merge、开 PR 或保留分支；该 skill 当前明确要求先跑完整测试，再由用户选择整合方式。[Superpowers finish](https://github.com/obra/superpowers/blob/b36e0829c6d0140e93cfef2ca599b1b07d4a7797/skills/finishing-a-development-branch/SKILL.md#L10-L82)

## 五、哪些模式符合 OpenSpec 契约，值得复制

### 5.1 值得直接复制

1. **项目级、完整 bundle、随 Git 版本化。** schema、所有 templates 和 VERSION 一起复制，不去改生成的 OpenSpec skills。
2. **保留标准 artifact id `specs`。** OpenSpec archive/sync 只从 `artifactPaths.specs.existingOutputPaths` 取 delta，换成别的 id 会失去标准 sync 路径。[archive 输入安全](https://github.com/Fission-AI/OpenSpec/blob/a0ddb60d040c61f4907436a9d91310934b1dda63/docs/customization.md#L131-L150)
3. **DAG 表达真实阅读依赖。** proposal/design 同源并行，tasks 必须同时读 specs 与 design；没有为了图好看而串成长链。
4. **粗 task / 细 plan 分层。** `tasks.md` 是 OpenSpec 状态与恢复点，`plan.md` 是 agent executor 输入；职责不重叠。
5. **重定向而非复制。** 同一次 brainstorm/plan 只产出 change 内一份文件，避免 `docs/superpowers/*` orphan。
6. **fail loud 的 capability PRECHECK。** 外部 skill 不存在时停止并报告，不静默切换到质量更低的执行器。
7. **实现后证据 artifact。** verify 与 retrospective 留在 change/archive 中，PR reviewer 能审阅“做了什么、如何证明、哪里偏离”，而不只看聊天声称。
8. **archive 后再开 PR。** 让主 spec 与完整 change 历史进入同一个 PR，避免 merge 后追加孤立 archive commit。

### 5.2 应在采用前修补

1. 在 `templates/spec.md` 和 specs instruction 加新 capability 的 `## Purpose`；当前 OpenSpec 内置 schema要求 50+ 字符，archive 会把它带入新主 spec。[当前内置 spec instruction](https://github.com/Fission-AI/OpenSpec/blob/a0ddb60d040c61f4907436a9d91310934b1dda63/schemas/spec-driven/schema.yaml#L79-L100)
2. 在 tasks instruction 明确“每个 task 的 checkbox 描述必须写验证方式”，与当前内置 schema 保持同步。[当前内置 tasks instruction](https://github.com/Fission-AI/OpenSpec/blob/a0ddb60d040c61f4907436a9d91310934b1dda63/schemas/spec-driven/schema.yaml#L172-L210)
3. 把“TDD 会传递激活”的强断言改成“每个 plan task 与 implementer dispatch 必须显式要求/验证 TDD”，并把具体 Superpowers 版本作为 release gate。
4. 统一唯一 post-apply 编排：要么 schema apply 全自动到底，要么 README 的 apply → verify → retro → archive；不能同时维护两套 canonical flow。
5. 为 Codex 增加 `AGENTS.md.fragment` 与 `$openspec-*` 示例，安装检查改为 Codex `/plugins`，不要把 Claude fragment 当跨平台规范。
6. 从 `verify.md` 删除“所有相关 commit 已推送”或把它移到 archive/finish 之后；当前模板要求已 push，但 schema 又规定 PR/push 是 archive 后最后一步，顺序自相矛盾。[verify template](https://github.com/JiangWay/openspec-schemas/blob/f5d40404856ad0f4ce9eb482cbb0e28cf434411f/superpowers-bridge/templates/verify.md#L69-L75) · [PR-last schema](https://github.com/JiangWay/openspec-schemas/blob/f5d40404856ad0f4ce9eb482cbb0e28cf434411f/superpowers-bridge/schema.yaml#L544-L567)

## 六、风险、限制与不粉饰的判断

| 严重度 | 事实 | 影响 / 改进 |
|---|---|---|
| 高 | 兼容矩阵仍固定 OpenSpec `1.4.1` + Superpowers `v5.1.0`，drift issue 未关闭。 | 当前 latest 的 schema validate 通过只证明 YAML/template/DAG 结构；发布前必须跑真实 Codex + Superpowers cycle。 |
| 高 | bridge 声称 SDD “内部强制” TDD；`v5.1.0` SDD 只写 subagents “should use” TDD，implementer prompt 是“task says to”才 TDD；`v6.3.0` SDD 主文件已无 TDD 引用。 | 不可依赖隐含传递激活。TDD 必须进入 plan task、dispatch prompt、review evidence。[v5.1 SDD](https://github.com/obra/superpowers/blob/f2cbfbefebbfef77321e4c9abc9e949826bea9d7/skills/subagent-driven-development/SKILL.md#L267-L279) · [v5.1 implementer](https://github.com/obra/superpowers/blob/f2cbfbefebbfef77321e4c9abc9e949826bea9d7/skills/subagent-driven-development/implementer-prompt.md#L29-L39) |
| 高 | OpenSpec graph 只看文件存在。`verify.requires: [plan]` 不能表达“apply 已完成”。 | `plan.md` 一出现 verify 就 ready；PRECHECK 是 prompt 层补丁，不是不可绕过的状态机。等待上游 `post_apply` 或在 CI/hook 写真正 gate。 |
| 高 | bridge 的 schema apply instruction、README quick flow、当前 OpenSpec apply skill 存在三套 orchestration。当前 apply skill会取 dynamic instruction，但自身仍定义通用逐 task loop，完成后建议 archive。[apply skill](https://github.com/Fission-AI/OpenSpec/blob/a0ddb60d040c61f4907436a9d91310934b1dda63/skills/openspec-apply-change/SKILL.md#L29-L55) · [通用 loop](https://github.com/Fission-AI/OpenSpec/blob/a0ddb60d040c61f4907436a9d91310934b1dda63/skills/openspec-apply-change/SKILL.md#L82-L112) | Agent 可能只展示 bridge instruction 却不调用 SDD，也可能 archive 两次。每次 apply 明说 schema instruction 为执行约束，并用 status 检查实际停点；bundle 应统一流程。 |
| 中 | 当前 Superpowers brainstorming 已分 Spike/Bounded/Architectural；Bounded 明确不写 spec/plan，Architectural 又会自动转 writing-plans，均可能与 bridge 固定 artifact 链冲突。[当前三路径](https://github.com/obra/superpowers/blob/b36e0829c6d0140e93cfef2ca599b1b07d4a7797/skills/brainstorming/SKILL.md#L22-L52) · [terminal state](https://github.com/obra/superpowers/blob/b36e0829c6d0140e93cfef2ca599b1b07d4a7797/skills/brainstorming/SKILL.md#L149-L154) | bridge 调用时必须覆盖默认输出和默认 handoff：只产 `brainstorm.md` 后返回 OpenSpec DAG，不能提前写 plan/实施。需要针对 v6 更新 instruction。 |
| 中 | `templates/spec.md` 没有新 capability `## Purpose`。 | archive 会生成 `TBD - created by archiving...`；不是 archive 阻断，但会造成主 spec 质量债，strict validation 对该 warning 判整体 invalid。 |
| 中 | bridge tasks 只要求 checkbox/小任务/依赖顺序，没有当前默认 schema 的逐项 verification。 | 粗 task 可能“完成”却无法客观验收；应同步上游 requirement。 |
| 中 | verify template 的“已推送”与 PR-last 冲突。 | verify 可能永远不能在规定顺序中全勾；改成“本地提交完整”，push 由 finish 检查。 |
| 中 | README/CLAUDE fragment 是 Claude-first，但描述中声称支持 Codex。 | Codex 用户照抄 `/opsx:*`、`claude plugin install`、CLAUDE.md 会失败或无效；需要独立适配文档。 |
| 中 | PRECHECK 全是自然语言 instruction。`schema validate` 不加载插件、不执行 skill、不验证提示词之间的矛盾。 | CI 应增加固定版本的真实 agent dogfood，至少人工 release checklist；不能只看绿色 schema badge。 |
| 低 | README 图写“PLANNING — 7 artifacts”，实际 apply 前只有 brainstorm/proposal/design/specs/tasks/plan 六类。 | 文档计数会误导，但不影响 DAG；修正文案即可。[图源码](https://github.com/JiangWay/openspec-schemas/blob/f5d40404856ad0f4ce9eb482cbb0e28cf434411f/superpowers-bridge/README.md#L217-L268) |

因此最终判断是：

- **作为 schema 设计参考：推荐。** 单 change 目录、DAG、双层计划、PRECHECK、verify/retro 都有借鉴价值。
- **作为当前 Codex 生产默认 schema：有条件推荐。** 先完成本节六项修补，固定上游版本，跑一次真实 cycle 后再设默认。
- **作为“复制目录即可获得 TDD + review 强保证”：不推荐这样宣传。** 现有证据不支持该强保证。

## 七、实测记录

### 7.1 本地环境

```text
macOS / zsh
Node.js v24.19.0
npm 11.17.0
系统 openspec 1.10.0
冒烟通过 npx 固定执行 @fission-ai/openspec@1.11.0
bridge commit f5d40404856ad0f4ce9eb482cbb0e28cf434411f
```

### 7.2 结构与状态冒烟

执行：

```bash
npx --yes @fission-ai/openspec@1.11.0 schema validate superpowers-bridge --verbose
npx --yes @fission-ai/openspec@1.11.0 schemas
npx --yes @fission-ai/openspec@1.11.0 new change bridge-smoke \
  --schema superpowers-bridge --json
npx --yes @fission-ai/openspec@1.11.0 status \
  --change bridge-smoke --json
npx --yes @fission-ai/openspec@1.11.0 instructions apply \
  --change bridge-smoke --json
```

结果：

- schema valid；`schemas` 列出 `superpowers-bridge (project)`。
- 新 change 的初始状态是 `brainstorm: ready`，其余按 DAG blocked。
- 复制到 `plan.md` 为止的六类文件后，apply state 为 `ready`，`contextFiles` 正确包含 brainstorm/proposal/design/specs/tasks/plan。
- 同时 `verify` 已变为 `ready`，尽管没有实现 commit；这复现了 post-apply timing mismatch。
- apply instructions 完整返回了 bridge 的 PRECHECK、worktree、SDD、verify、retro、archive、finish 提示，说明 OpenSpec CLI 没有丢掉 schema instruction；但是否遵循仍由 agent skill/prompt 行为决定。

OpenSpec `schema validate` 本身只解析 Zod 结构、检查重复 id、`requires` 引用与 cycle；不理解 instruction 语义。[schema parser](https://github.com/Fission-AI/OpenSpec/blob/a0ddb60d040c61f4907436a9d91310934b1dda63/src/core/artifact-graph/schema.ts#L20-L44)

### 7.3 strict validate 与 archive 冒烟

使用官方 OpenSpec 已归档 change 的合法 proposal/design/tasks/delta 内容，补齐 bridge 的 brainstorm/plan/verify/retro 文件后执行：

```bash
npx --yes @fission-ai/openspec@1.11.0 validate bridge-smoke \
  --type change --strict --json
npx --yes @fission-ai/openspec@1.11.0 archive bridge-smoke -y --json
npx --yes @fission-ai/openspec@1.11.0 validate --all --strict --json
```

结果：

1. change strict validation：`valid: true`。
2. archive：成功移动到 `openspec/changes/archive/2026-08-27-bridge-smoke`，同步 6 个 ADDED requirements。
3. 新主 spec 的 Purpose 自动变成：`TBD - created by archiving change bridge-smoke. Update Purpose after archive.`
4. archive 后全量 strict validation：该 placeholder 产生 WARNING，item `valid: false`。

这精确限定了 Purpose 问题：**缺 Purpose 不阻止 change strict validation 或 archive；它在 archive 后制造主 spec warning/质量债。** OpenSpec 当前内置 schema 已专门要求新 capability 先写 Purpose，bridge 尚未同步。[内置模板](https://github.com/Fission-AI/OpenSpec/blob/a0ddb60d040c61f4907436a9d91310934b1dda63/schemas/spec-driven/templates/spec.md#L1-L11)（本地 `tmp/OpenSpec/schemas/spec-driven/templates/spec.md:1-11`）

### 7.4 上游 CI 能证明什么

bridge 当前提交的结构 CI 成功，最新 main run 是 [`27265358523`](https://github.com/JiangWay/openspec-schemas/actions/runs/27265358523)；2026-08-24 weekly drift run [`32740579165`](https://github.com/JiangWay/openspec-schemas/actions/runs/32740579165) 也成功并确认 OpenSpec 1.10.0 结构 validate 通过。

但 workflow 只安装 OpenSpec、复制 schema、执行 `openspec schema validate` 和 `openspec schemas`；没有安装 Superpowers，也没有驱动真实 brainstorm → apply → verify → archive cycle。[CI 定义](https://github.com/JiangWay/openspec-schemas/blob/f5d40404856ad0f4ce9eb482cbb0e28cf434411f/.github/workflows/validate-schemas.yml#L1-L38)（本地 `.github/workflows/validate-schemas.yml:1-38`）

本次也未冒充做 Superpowers 行为测试：当前工作区没有安装/暴露 bridge 所需的 Superpowers skills，真实流程还包含用户审批、subagent、worktree、代码测试和分支整合。可诚实得出的最高结论是“OpenSpec 1.11.0 结构与 archive 冒烟通过，发现上述行为风险”，不是“端到端兼容已验证”。

## 八、采用检查清单

- [ ] 固定 bridge commit/tag、OpenSpec 版本、Superpowers 版本，而不是只写 `latest`
- [ ] `openspec schema validate superpowers-bridge --verbose` 通过
- [ ] `openspec schema which superpowers-bridge` 确认解析的是项目副本
- [ ] Codex 使用 `$openspec-*`，Superpowers 从 Codex plugin marketplace 安装
- [ ] 为 Codex 写 `AGENTS.md` 路由，不复制 Claude fragment
- [ ] 新 capability template/instruction 已加入 `## Purpose`
- [ ] 每个 `tasks.md` checkbox 都写验证方式
- [ ] TDD 写入 plan 与 dispatch，并要求 RED/GREEN 输出证据
- [ ] apply 后用 status 决定下一步，不依赖 README 的固定命令序列
- [ ] verify 的 push 检查已修正为不与 PR-last 冲突
- [ ] 至少完成一次真实项目 dogfood：brainstorm → plan → worktree/SDD → test/review → verify → retro → archive → finish
- [ ] archive 后再次 `openspec validate --all --strict --json`，无 TBD Purpose

满足以上条件后，`superpowers-bridge` 才从“有价值的 prompt-layer 原型”升级为“项目可依赖的工作流合同”。
