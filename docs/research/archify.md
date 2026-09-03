# Archify 方法及其在 Tina 架构规划阶段的适用性

> 研究快照：2026-09-03。稳定基线为 Archify `v2.16.0`，tag 指向提交 [`c826e6c3a7abad19c0f3cd1ca57207d54b1ad8de`](https://github.com/tt-a1i/archify/tree/c826e6c3a7abad19c0f3cd1ca57207d54b1ad8de)；同时检查了 `main` 提交 [`06dd052602dd9a369e4d034e24faef0917b5a60c`](https://github.com/tt-a1i/archify/tree/06dd052602dd9a369e4d034e24faef0917b5a60c)，其身份是 `v2.17.0-dev.1`，不是稳定发布。[稳定版本声明](https://github.com/tt-a1i/archify/blob/c826e6c3a7abad19c0f3cd1ca57207d54b1ad8de/README_EN.md#L22-L26) · [开发版本声明](https://github.com/tt-a1i/archify/blob/06dd052602dd9a369e4d034e24faef0917b5a60c/CHANGELOG.md#L5-L12)

## 结论

Archify 适合充当 Tina 的**架构共识产物渲染器和机械校验器**：agent 把已调查、已讨论的架构事实和设计意图写成 typed JSON IR，Archify 校验结构与图形、生成可交互 HTML，并可精确展示两个 Architecture 快照之间的 authored delta。它不发现完整架构，也不判断架构设计是否正确、是否安全、是否低风险或是否可合并；这些判断仍由人类、Tina 的领域对齐、ADR 和 proposal review 承担。[产品工作方式](https://github.com/tt-a1i/archify/blob/c826e6c3a7abad19c0f3cd1ca57207d54b1ad8de/README_EN.md#L181-L202) · [Delta 明示的推断边界](https://github.com/tt-a1i/archify/blob/c826e6c3a7abad19c0f3cd1ca57207d54b1ad8de/archify/delta/architecture-delta.mjs#L313-L316)

建议在 `$tina-propose-plan` 内加入一个**条件触发的架构对齐步骤**，位置是 research/domain alignment 之后、size gate 和 Proposal Plan 定稿之前。第一版新增一个薄的私有 `$tina-architecture` wrapper，由它维护一个独立 `tina_architect` subagent 的绘图与反馈 loop；不改 OpenSpec schema。Archify Skill 作为固定 revision 的上游快照随 Tina 安装和同步。

## Archify 实际提供什么

Archify 是一个 Agent Skill 加 Node.js CLI。agent 负责理解问题和编写小型 JSON IR，确定性 renderer 负责把 IR 编译成独立 HTML/inline SVG。输入可以是自然语言、代码库事实或 Mermaid 拓扑；Mermaid 只作为语义输入，agent 会重写成 Archify JSON，而不是机械套皮。[定位](https://github.com/tt-a1i/archify/blob/c826e6c3a7abad19c0f3cd1ca57207d54b1ad8de/README_EN.md#L13-L20) · [Mermaid 处理规则](https://github.com/tt-a1i/archify/blob/c826e6c3a7abad19c0f3cd1ca57207d54b1ad8de/archify/SKILL.md#L67-L73)

它支持五类模型：

| 类型 | 结构重点 | 适合回答的问题 |
|---|---|---|
| `architecture` | components、boundaries、connections | 系统组件、服务、存储、部署/安全边界 |
| `workflow` | lanes、phases、groups、mainPath、nodes、edges | 流程、职责、审批、分支与异常 |
| `sequence` | participants、segments、messages、activations | 一次请求或异步交互的时间顺序 |
| `dataflow` | stages、nodes、flows | 数据来源、变换、存储、血缘与敏感边界 |
| `lifecycle` | lanes、states、transitions | 状态、事件、重试、等待和终态 |

这些类型及结构数组由五份严格 JSON Schema 定义，未知字段会因 `additionalProperties: false` 被拒绝。[Schema 总览](https://github.com/tt-a1i/archify/blob/c826e6c3a7abad19c0f3cd1ca57207d54b1ad8de/archify/schemas/README.md#L1-L20) 对 Tina 的“系统架构设计”应默认使用 `architecture`；只有某个待确认问题确实涉及调用时序、数据移动、状态或跨角色流程时，才补一张对应类型的图。Architecture Delta 目前也只支持 `architecture`。[CLI 接口](https://github.com/tt-a1i/archify/blob/c826e6c3a7abad19c0f3cd1ca57207d54b1ad8de/archify/bin/archify.mjs#L15-L31)

Architecture IR 至少包含 `schema_version`、`diagram_type`、`meta.title` 和 `components`；component 有稳定 `id`、语义类型和 label，可选位置、大小与 source evidence，此外可声明 boundaries 和 connections。[Architecture Schema](https://github.com/tt-a1i/archify/blob/c826e6c3a7abad19c0f3cd1ca57207d54b1ad8de/archify/schemas/architecture.schema.json#L1-L35) · [组件和关系字段](https://github.com/tt-a1i/archify/blob/c826e6c3a7abad19c0f3cd1ca57207d54b1ad8de/archify/schemas/architecture.schema.json#L83-L174)

## 方法与生命周期

Archify 的正常 authoring loop 很窄：

1. agent 根据问题选一种图，只读取相应 schema、shared schema 和一个形状示例；示例只提供字段形状，不能充当事实。
2. agent 先写 candidate JSON；普通图以一条主路径、短支线、稀疏标签和最多 12 个主要节点起步。
3. 每次修改后运行 `validate`。诊断返回稳定 code、精确 subject、测量 evidence 和允许的 fixes；agent 每轮只修诊断指向的局部问题。
4. candidate 通过后冻结，`deliver` 从精确字节生成并检查 HTML，只在全部检查通过后原子替换旧输出。
5. 若需要真实浏览器证据，再对已交付的同一 HTML 运行 `visual-check`；感知层面的视觉质量仍需人类或能看图的 reviewer 判断。

上述顺序来自 Skill 的 fast authoring path 和交付契约。[authoring loop](https://github.com/tt-a1i/archify/blob/c826e6c3a7abad19c0f3cd1ca57207d54b1ad8de/archify/SKILL.md#L15-L35) · [原子交付](https://github.com/tt-a1i/archify/blob/c826e6c3a7abad19c0f3cd1ca57207d54b1ad8de/archify/references/delivery-contract.md#L3-L19) · [感知评审边界](https://github.com/tt-a1i/archify/blob/c826e6c3a7abad19c0f3cd1ca57207d54b1ad8de/archify/references/delivery-contract.md#L61-L75)

这套分工适合人机协作：agent 处理仓库调查、IR 编写、机械验证和局部修图；人类通过 HTML 的 focus、search、relationship trace 和 guided views 检查共同理解，并用自然语言要求针对性修改。Archify 保留 typed source 以支持诸如“加入 Redis”“移动 auth”“突出 rollback path”的局部迭代。[对话式迭代](https://github.com/tt-a1i/archify/blob/c826e6c3a7abad19c0f3cd1ca57207d54b1ad8de/README_EN.md#L120-L136) · [viewer 能力](https://github.com/tt-a1i/archify/blob/c826e6c3a7abad19c0f3cd1ca57207d54b1ad8de/archify/SKILL.md#L118-L122)

## 更新、比较与 reconciliation

Architecture Delta 先独立验证 base/head，再按 authored stable ID 比较。component 变化分为 semantic、evidence、geometry；connection 变化分为 topology、semantic、geometry；boundary 变化分为 scope、geometry；presentation 与 provenance 单独报告。[分类实现](https://github.com/tt-a1i/archify/blob/c826e6c3a7abad19c0f3cd1ca57207d54b1ad8de/archify/delta/architecture-delta.mjs#L151-L167) · [receipt 汇总](https://github.com/tt-a1i/archify/blob/c826e6c3a7abad19c0f3cd1ca57207d54b1ad8de/archify/delta/architecture-delta.mjs#L226-L317)

稳定 ID 是 reconciliation 的关键契约。缺失或重复的 component/connection ID 会失败；两个快照没有共同 component ID 时也会失败。同名 component 如果改了 ID，会被视为删除旧节点并新增新节点，而不是 rename。[配对约束](https://github.com/tt-a1i/archify/blob/c826e6c3a7abad19c0f3cd1ca57207d54b1ad8de/archify/delta/architecture-delta.mjs#L77-L111) · [共同身份检查](https://github.com/tt-a1i/archify/blob/c826e6c3a7abad19c0f3cd1ca57207d54b1ad8de/archify/delta/architecture-delta.mjs#L226-L240)

Archify 不会把代码变化自动同步进架构模型。所谓 update 是 agent 修改同一份 typed source、保留无关结构；所谓 compare 是比较两份 authored snapshots。仓库证据模式也只验证作者声明的引用：公开 GitHub URL、40 位 commit SHA、本地 checkout 的 origin、commit、blob 和行号必须匹配；它没有证明未引用部分，也不会从文件相邻或命名推断运行时因果。[仓库调查规则](https://github.com/tt-a1i/archify/blob/c826e6c3a7abad19c0f3cd1ca57207d54b1ad8de/archify/references/authoring-contract.md#L179-L187) · [证据校验实现](https://github.com/tt-a1i/archify/blob/c826e6c3a7abad19c0f3cd1ca57207d54b1ad8de/archify/renderers/shared/repository-evidence.mjs#L81-L119) · [Git/blob/line 校验](https://github.com/tt-a1i/archify/blob/c826e6c3a7abad19c0f3cd1ca57207d54b1ad8de/archify/renderers/shared/repository-evidence.mjs#L121-L235)

因此，Tina 不能把 `validate` 通过解释为“架构正确”。它只说明 JSON、引用、布局和交付产物满足 Archify 契约。`proofLevel: revision-pinned` 也只说明两侧存在已验证的 source evidence，并不说明每个节点都对应代码，更不说明目标设计可实施；Delta 的 receipt 明确声明不推断 runtime impact、causality、risk 或 mergeability。[proof level 计算](https://github.com/tt-a1i/archify/blob/c826e6c3a7abad19c0f3cd1ca57207d54b1ad8de/archify/delta/architecture-delta.mjs#L243-L257) · [限制](https://github.com/tt-a1i/archify/blob/c826e6c3a7abad19c0f3cd1ca57207d54b1ad8de/archify/delta/architecture-delta.mjs#L313-L316)

## 与 Tina 当前流程的接缝

当前 `$tina-propose-plan` 已经按顺序读取 Domain Model/ADR/代码、补研究、grill、做 size gate，再调用 `$openspec-propose` 或为多 Change 写 Proposal Plan；架构步骤应插在 grill/domain alignment 后、size gate 前，因为系统边界、接口和依赖会直接决定 Change 如何拆分。[当前流程](../../skills/tina-propose-plan/SKILL.md)

当前 `design.md` 是**单个 Change 的条件性 OpenSpec artifact**，在 proposal 之后生成，用来记录实现所需的技术决策。它无法承担多 Change 拆分前的系统级 target architecture；把系统模型塞进每个 Change 的 `design.md` 还会产生多份容易漂移的副本。[Tina schema](../../schema/tina/schema.yaml) `change.html` 也是单个 Change 的 review projection，Markdown 才是权威源，因此不应复用它来冒充系统架构模型。[领域定义](../../CONTEXT.md)

推荐的 planning flow：

```text
$tina-research（可选）
        ↓
$tina-propose-plan：Domain Model + ADR + grilling
        ↓
是否存在跨模块拓扑/边界/接口决策？ ── 否 ──→ size gate
        │ 是
        ↓
$tina-architecture：父 agent 确定范围与证据
        ↓
tina_architect subagent：编写/更新 Architecture JSON
        ↓
Archify validate + 临时 HTML / Before-Delta-After
        ↓
人类检查语义和设计；agent 按反馈改 JSON，重新校验
        ↓
确认模型哈希与受影响 stable IDs → size gate → Proposal Plan
        ↓
$tina-propose-run：每个 Change 引用同一模型及自己的 IDs
```

### 触发条件

满足任一条件时调用 `$tina-architecture`：

- Change 跨越多个模块、服务、进程、数据存储或信任边界；
- 需要新增/移动 ownership、部署区域、安全边界或外部依赖；
- 多个 Change 的拆分取决于共享组件、接口或迁移顺序；
- 人类明确要求系统架构图或 target architecture。

纯局部行为修改、只影响一个已有模块且不会改变边界时跳过。Archify 自己也建议 Architecture 保持一条主干和 6–12 个主要 component；它适合高层共识，不适合穷举代码结构。[Architecture authoring 约束](https://github.com/tt-a1i/archify/blob/c826e6c3a7abad19c0f3cd1ca57207d54b1ad8de/archify/references/authoring-contract.md#L148-L155)

### 最小持久化模型

只跟踪一份权威源：

```text
docs/architecture/<scope>.architecture.json
```

它表达当前分支已经确认的 architecture intent。首次建立时直接 review；以后更新时从 Git 基线取旧文件到临时目录，与工作树 candidate 做 Architecture Delta。HTML、截图和大型 compare artifact 默认放临时目录供当次人工评审，不提交；需要长期 PR 证据时再显式保留。这样避免把每份约 700 KB 的自包含 viewer 复制进每个 Proposal Plan，同时保留可重建、可 diff 的小型 JSON 源。Archify 的 deliver receipt 可提供 specification SHA-256 和字节数，用来把 Proposal Plan 绑定到确切模型版本。[交付 receipt](https://github.com/tt-a1i/archify/blob/c826e6c3a7abad19c0f3cd1ca57207d54b1ad8de/archify/references/delivery-contract.md#L77-L89)

Proposal Plan 新增一个按需出现的 `Architecture Alignment` 段，记录：

- canonical JSON 路径；
- `specification_sha256`；
- human confirmation 结论；
- 每个 Change 涉及的 component/connection stable IDs；
- 仍可安全延期的问题；任何会改变边界、拆分或任务顺序的问题必须先解决。

`$tina-propose-run` 开始时只需重新计算 JSON hash；不匹配就停止并返回 `$tina-propose-plan`，匹配则让 proposer 读取同一模型并在 proposal/design 中引用对应 stable IDs。这个 gate 防止人类确认后模型被静默改写，也不需要把 Architecture 加入 OpenSpec artifact DAG。

### 责任边界

| 产物 | 权威内容 |
|---|---|
| `CONTEXT.md` | 规范词汇，不承载架构图 |
| ADR | 难以逆转、存在真实取舍的架构决定及理由 |
| Architecture JSON | 已确认的组件、边界、连接和展示所需最少元数据 |
| Proposal Plan | Change 拆分、依赖、停止条件，以及对 Architecture stable IDs 的映射 |
| Change `design.md` | 单个 Change 如何实现架构决定，不复制整张系统模型 |
| Archify HTML/Delta | 非权威的人类 review projection 和机械 receipt |

这一分工延续 Tina 已有原则：Domain Model、ADR、Proposal Plan 和 Change artifact 各自只保留自己的事实，图形投影不取代 Markdown 决策记录。

## 依赖与分发建议

`v2.16.0` 的 Skill package 要求 Node.js `>=18`，运行时使用随包提交的 validator，不要求在目标项目安装 npm dependencies；浏览器证据另外需要本机 Chrome/Chromium。[package metadata](https://github.com/tt-a1i/archify/blob/c826e6c3a7abad19c0f3cd1ca57207d54b1ad8de/archify/package.json#L1-L13) · [runtime validator](https://github.com/tt-a1i/archify/blob/c826e6c3a7abad19c0f3cd1ca57207d54b1ad8de/archify/schemas/README.md#L153-L164) · [browser evidence](https://github.com/tt-a1i/archify/blob/c826e6c3a7abad19c0f3cd1ca57207d54b1ad8de/archify/references/delivery-contract.md#L21-L41) Archify 成为 Tina 依赖后，Tina 的 Node.js 前置条件也应明确为 `>=18`。[Tina prerequisites](../../README.md#prerequisites)

本地按 pinned Git tree 统计，`v2.16.0` 的 `archify/` 有 190 个 tracked files、约 7.23 MB；发布 ZIP 有 76 个 entries、展开约 5.89 MB。大部分体积来自自包含 HTML 模板、viewer 示例和生成 validator。Tina 接受这部分体积作为可复现安装的代价；统计对象可从 [v2.16.0 tree](https://github.com/tt-a1i/archify/tree/c826e6c3a7abad19c0f3cd1ca57207d54b1ad8de/archify) 复核。

Archify 自有代码采用 MIT License，并要求副本保留版权与许可文本。[许可证](https://github.com/tt-a1i/archify/blob/c826e6c3a7abad19c0f3cd1ca57207d54b1ad8de/LICENSE#L1-L21) `main` 的 `v2.17.0-dev.1` 又加入了第三方品牌图标 notices，并明确 Archify 的 MIT 不替代第三方版权、商标和品牌规则。[第三方声明](https://github.com/tt-a1i/archify/blob/06dd052602dd9a369e4d034e24faef0917b5a60c/archify/THIRD_PARTY_NOTICES.md#L1-L24) 这项修复尚未进入 `v2.16.0` 稳定 tag。[开发变更记录](https://github.com/tt-a1i/archify/blob/06dd052602dd9a369e4d034e24faef0917b5a60c/CHANGELOG.md#L5-L12)

因此采用以下依赖策略：

1. **把 Archify 作为 Tina 的 pinned upstream dependency。** `dependencies.env` 保存 repository 和 exact commit，版本不写进 wrapper、schema 或 Target Instructions。首个集成候选使用已包含第三方声明的 `06dd0526...`，由 Tina smoke test 背书这一个精确快照；后续稳定版发布后再通过 updater 切换。候选 revision 必须同时包含完整 Skill package、LICENSE 和适用的 THIRD_PARTY_NOTICES。
2. **只通过现有 updater 刷新。** 扩展 `update-dependencies.sh` 的可选参数，使它从指定 revision 暂存 Archify Skill、运行 `doctor` 和一个 architecture validate/deliver smoke check，全部通过后才替换 `vendor/archify/` 和 pin。不要用可变的 `npx skills add ...@main` 更新已发布 bundle。
3. **init 总是安装。** `install.sh` 对 `vendor/archify/` 使用与 Matt Pocock skills 相同的目录冲突检查，再复制到目标 `.agents/skills/archify/`；目标已有不同内容时继续拒绝覆盖。
4. **sync 自动纳入。** `$tina-sync` 通过当前 bundle 的 `install.sh` 构造 desired payload，并把 staged skill files 视为 managed payload，因此 installer 加入 Archify 后无需另写一套同步算法；manifest 会逐文件记录其 source/target hash 和 managed/custom policy。
5. **私有策略仍留在 Tina。** vendored `archify/SKILL.md` 保持上游原样；触发条件、Architecture JSON 路径、独立 architect subagent、人工确认、Proposal Plan handoff 和 hash gate 写在 `$tina-architecture` wrapper 与 `tina_architect` preset。

## 第一版实施范围

第一版只需要：

- 新增 `skills/tina-architecture/SKILL.md`，负责触发判断、输入收集、Archify 调用、人工确认和 handoff；
- 新增 `agents/tina-architect.toml`；父 agent 负责范围和人类交互，同一个 architect subagent 负责绘图、校验与按反馈修订；
- 在 `$tina-propose-plan` 的 domain alignment 与 size gate 之间条件调用它；
- 让 Proposal Plan 在调用过架构步骤时记录 Architecture path、hash、确认结果和 Change-to-ID 映射；
- 让 `$tina-propose-run` 校验 hash 并把模型路径/IDs 传给 proposer；
- 扩展 `dependencies.env` 和 `update-dependencies.sh`，维护 `vendor/archify/` 的 exact-commit snapshot；
- 让 `install.sh` 安装 `$tina-architecture` 与 vendored `$archify`，让 `test.sh` 验证幂等、冲突保护和 Archify CLI smoke check；
- 更新 Tina init/sync 的 managed payload 文档和目标文件清单。

不改 `schema/tina/schema.yaml`，不新增 architecture artifact，不默认提交 HTML，不在第一版实现代码到架构的自动 drift detection。后续只有在真实项目出现“实现已偏离已确认 JSON、人工 review 没发现”的重复问题时，才把 repository evidence reconciliation 加到 `$tina-verify`。
