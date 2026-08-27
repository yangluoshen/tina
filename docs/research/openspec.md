# OpenSpec：Schema、Codex 默认工作流、设计哲学与最佳实践

> 研究快照：OpenSpec `v1.11.0`，提交 [`a0ddb60d040c61f4907436a9d91310934b1dda63`](https://github.com/Fission-AI/OpenSpec/tree/a0ddb60d040c61f4907436a9d91310934b1dda63)，2026-08-27。结论只使用 OpenSpec 官方仓库的发布文档、内置 schema、生成技能和源码。仓库中的 `docs-lab/` 是待切换的新文档草案（其自身称之为 old-to-new drafting/cutover map），因此本报告不把它作为行为依据；相关结论均以当前 `docs/` 或源码为准。[来源](https://github.com/Fission-AI/OpenSpec/blob/a0ddb60d040c61f4907436a9d91310934b1dda63/docs-lab/sources.md#L1-L42)

## 结论先行

1. OpenSpec 的 **schema 不是业务数据 schema**，而是一个“规划产物工作流”：`schema.yaml` 声明 artifact、输出路径、模板、生成指令和依赖关系，`templates/` 决定 Markdown 骨架；`apply` 决定实现前置条件与任务进度文件。[官方文档](https://github.com/Fission-AI/OpenSpec/blob/a0ddb60d040c61f4907436a9d91310934b1dda63/docs/customization.md#L163-L177) · [运行时类型定义](https://github.com/Fission-AI/OpenSpec/blob/a0ddb60d040c61f4907436a9d91310934b1dda63/src/core/artifact-graph/types.ts#L24-L57)
2. 构建新 schema 的首选路径是 **fork 内置 `spec-driven`，只改差异**；只有现有流程完全不合适时才 `schema init`。项目级 schema 位于 `openspec/schemas/<name>/`，应随代码提交。[官方文档](https://github.com/Fission-AI/OpenSpec/blob/a0ddb60d040c61f4907436a9d91310934b1dda63/docs/customization.md#L163-L216)
3. Codex 集成是 **skills-only**：文件写到 `.agents/skills/openspec-*/SKILL.md`，调用形式是 `$openspec-<skill>`，而不是文档中跨工具使用的 `/opsx:*` 写法。[官方工具矩阵](https://github.com/Fission-AI/OpenSpec/blob/a0ddb60d040c61f4907436a9d91310934b1dda63/docs/supported-tools.md#L1-L41)
4. 默认 `core` profile 安装六个工作流：`explore`、`propose`、`apply`、`update`、`sync`、`archive`。日常主循环是“可选探索 → 提案 → 人工审阅 → 实现 → 归档”，`update` 与 `sync` 是需要时插入的动作。[官方工作流](https://github.com/Fission-AI/OpenSpec/blob/a0ddb60d040c61f4907436a9d91310934b1dda63/docs/workflows.md#L31-L117) · [profile 源码](https://github.com/Fission-AI/OpenSpec/blob/a0ddb60d040c61f4907436a9d91310934b1dda63/src/core/profiles.ts#L10-L32)
5. 其核心哲学是：**fluid not rigid、iterative not waterfall、easy not complex、brownfield-first**。落到工程上，就是以 Git 中的 plain Markdown 作为人机共同计划，以 delta spec 描述变化，并允许在实现中随时修订 artifact。[官方概念](https://github.com/Fission-AI/OpenSpec/blob/a0ddb60d040c61f4907436a9d91310934b1dda63/docs/concepts.md#L5-L24)

## 一、如何构建新的 OpenSpec schema

### 1.1 先判断是否真的需要 schema

OpenSpec 有两级常用定制：

- 只需加入技术栈、团队约束、某类 artifact 的额外规则，优先改 `openspec/config.yaml` 的 `context`、`rules`、`operations`。
- 需要增删/重命名 artifact、改变依赖顺序、文件名或文档结构时，才建立 custom schema。

官方把 Project Config 定位为“Most teams”，Custom Schemas 定位为“unique processes”；项目配置会把 context 注入所有 artifact、rules 只注入匹配的 artifact。[官方文档](https://github.com/Fission-AI/OpenSpec/blob/a0ddb60d040c61f4907436a9d91310934b1dda63/docs/customization.md#L3-L20) · [注入行为](https://github.com/Fission-AI/OpenSpec/blob/a0ddb60d040c61f4907436a9d91310934b1dda63/docs/customization.md#L63-L103)

### 1.2 推荐路径：fork 一个可工作的 schema

从项目根目录执行：

```bash
openspec schema fork spec-driven my-workflow
```

它会生成：

```text
openspec/schemas/my-workflow/
├── schema.yaml
└── templates/
    ├── proposal.md
    ├── spec.md
    ├── design.md
    └── tasks.md
```

随后按最小差异修改 `schema.yaml` 和模板，验证并设置默认值：

```bash
openspec schema validate my-workflow
openspec schema which my-workflow
```

```yaml
# openspec/config.yaml
schema: my-workflow
```

这条路径复用内置 schema 已有的生成指令、delta spec 约定和 task 格式，出错面最小。官方也称 fork 是最快的定制方式；schema 解析顺序为 CLI flag → change metadata → project config → `spec-driven` 默认值。[官方 fork 指南](https://github.com/Fission-AI/OpenSpec/blob/a0ddb60d040c61f4907436a9d91310934b1dda63/docs/customization.md#L179-L201) · [选择优先级](https://github.com/Fission-AI/OpenSpec/blob/a0ddb60d040c61f4907436a9d91310934b1dda63/docs/customization.md#L152-L160)

例如，要在默认流程中加入实现前审阅，保留 fork 文件里的 `proposal`、`specs`、`design`、`tasks`，只新增以下 artifact：

```yaml
  - id: review
    generates: review.md
    description: Pre-implementation review
    template: review.md
    instruction: Check scope, spec coverage, risk, and unresolved decisions.
    requires: [specs, design]
```

同时在原 `tasks` 的 `requires` 中加入 `review`，并新增 `templates/review.md`；其余内容不动。官方文档给出了同类改法。[官方示例](https://github.com/Fission-AI/OpenSpec/blob/a0ddb60d040c61f4907436a9d91310934b1dda63/docs/customization.md#L382-L409)

### 1.3 从零开始：`schema init`

当内置流程完全不合适时：

```bash
# 交互式
openspec schema init research-first

# 非交互式；同时设为项目默认
openspec schema init rapid \
  --description "Rapid iteration workflow" \
  --artifacts proposal,tasks \
  --default
```

当前 `schema init --artifacts` 只接受 `proposal,specs,design,tasks` 四个内置 id；不传时默认生成全部四种。需要 `review`、`test-plan` 等自定义 artifact 时，先 init/fork，再手工编辑 YAML 和模板。[命令源码](https://github.com/Fission-AI/OpenSpec/blob/a0ddb60d040c61f4907436a9d91310934b1dda63/src/commands/schema.ts#L1016-L1157) · [内置 artifact 列表](https://github.com/Fission-AI/OpenSpec/blob/a0ddb60d040c61f4907436a9d91310934b1dda63/src/commands/schema.ts#L469-L502)

`schema init` 会自行搭建依赖、创建模板并在安装前验证生成结果；含 `tasks` 时还会自动生成 `apply.requires: [tasks]` 与 `tracks: tasks.md`。[源码](https://github.com/Fission-AI/OpenSpec/blob/a0ddb60d040c61f4907436a9d91310934b1dda63/src/commands/schema.ts#L1159-L1241)

### 1.4 `schema.yaml` 的运行时契约

| 字段 | 含义 | 实践要点 |
|---|---|---|
| `name` | schema 内部名称 | 使用与目录相同的 kebab-case 名称。实际查找键是目录名。 |
| `version` | 正整数版本 | 当前 contract 未定义 schema 自动迁移行为；团队自己管理兼容性。 |
| `description` | 列表中展示的说明 | 简短说明适用场景。 |
| `artifacts` | 非空 artifact 列表 | 声明顺序也是多个节点同时 ready 时的先后顺序。 |
| `id` | artifact 唯一 id | 被 `requires`、project rules、命令和 apply 引用。 |
| `generates` | change 目录内相对路径或 glob | 禁止绝对路径与 `..`；glob 如 `specs/**/*.md`。 |
| `template` | `templates/` 下相对路径 | template 是结构，不会被简单复制；agent 根据它填充内容。 |
| `instruction` | agent 生成语义 | 写“要产出什么、质量标准是什么”，避免只写文件标题。 |
| `requires` | artifact 依赖 id | 必须存在、不可循环；形成 DAG。 |
| `apply.requires` | 实现开始前必须存在的 artifact | 通常指向最终计划 artifact。 |
| `apply.tracks` | checkbox 任务文件 | 若要进度与可恢复实现，指向如 `tasks.md`。 |

字段的可执行定义在 Zod runtime schema 中；解析器还会检查重复 id、无效 artifact 依赖与环。[类型定义](https://github.com/Fission-AI/OpenSpec/blob/a0ddb60d040c61f4907436a9d91310934b1dda63/src/core/artifact-graph/types.ts#L24-L57) · [图验证](https://github.com/Fission-AI/OpenSpec/blob/a0ddb60d040c61f4907436a9d91310934b1dda63/src/core/artifact-graph/schema.ts#L23-L44)

两个容易误解的运行时事实：

- Artifact 是否完成，主要按 `generates` 对应文件/glob **是否存在**判断，不检查内容质量。[状态源码](https://github.com/Fission-AI/OpenSpec/blob/a0ddb60d040c61f4907436a9d91310934b1dda63/src/core/artifact-graph/state.ts#L6-L36)
- 依赖图决定 ready/blocked 与拓扑次序；多个 ready 节点按 `artifacts:` 声明顺序打破平局。[图源码](https://github.com/Fission-AI/OpenSpec/blob/a0ddb60d040c61f4907436a9d91310934b1dda63/src/core/artifact-graph/graph.ts#L20-L38) · [排序实现](https://github.com/Fission-AI/OpenSpec/blob/a0ddb60d040c61f4907436a9d91310934b1dda63/src/core/artifact-graph/graph.ts#L91-L160)

因此，`requires` 是上下文依赖，不是语义审批系统。如果 `review.md` 必须包含 `VERDICT: APPROVED` 才能继续，OpenSpec 本身不会检查该文本；应在 CI/hook 中加真正的 gate。官方社区 schema 说明也明确指出 OpenSpec 只检查 artifact 是否存在。[官方说明](https://github.com/Fission-AI/OpenSpec/blob/a0ddb60d040c61f4907436a9d91310934b1dda63/docs/customization.md#L413-L425)

### 1.5 验证与冒烟测试

最低验证闭环：

```bash
# 1. 静态检查 YAML、模板、artifact 引用与依赖环
openspec schema validate my-workflow --verbose

# 2. 确认实际解析到项目级副本，而不是同名 user/package schema
openspec schema which my-workflow

# 3. 建一个真实的测试 change
openspec new change schema-smoke --schema my-workflow

# 4. 检查顺序、状态和每个 artifact 的最终提示
openspec status --change schema-smoke
openspec instructions proposal --change schema-smoke
```

`schema validate` 会解析 runtime schema，并确认每个模板存在且没有越出 `templates/`；依赖引用和环由 parser 检查。[验证源码](https://github.com/Fission-AI/OpenSpec/blob/a0ddb60d040c61f4907436a9d91310934b1dda63/src/commands/schema.ts#L139-L236)

验证仍不是完备证明：它不判断 instruction/template 能否产出好内容，也不执行语义审批；此外当前 parser 的依赖检查只遍历 artifact 的 `requires`，没有对 `apply.requires` 做同样的 id 引用检查。因此手工检查 `apply.requires`，并至少走一次 `status`/`instructions` 冒烟流程。[parser 源码](https://github.com/Fission-AI/OpenSpec/blob/a0ddb60d040c61f4907436a9d91310934b1dda63/src/core/artifact-graph/schema.ts#L33-L44) · [artifact-only 引用检查](https://github.com/Fission-AI/OpenSpec/blob/a0ddb60d040c61f4907436a9d91310934b1dda63/src/core/artifact-graph/schema.ts#L60-L75)

### 1.6 Schema 最佳实践

1. **尽量 fork，不从空白重写。** 复用默认 schema 中成熟的行为/设计/任务提示，只维护团队真正不同的部分。
2. **保留 `specs` id，若仍希望默认 sync/archive 合并 delta spec。** 当前 archive/sync 只把 `artifactPaths.specs.existingOutputPaths` 当作 delta spec 来源，不会从其他 artifact 猜测。[官方行为说明](https://github.com/Fission-AI/OpenSpec/blob/a0ddb60d040c61f4907436a9d91310934b1dda63/docs/customization.md#L131-L150)
3. **模板管结构，instruction 管语义，config 管项目差异。** 不要在 schema 内重复每个项目都不同的技术栈；把它放到 `config.yaml`，避免 fork 无谓分叉。
4. **依赖只表达“生成此物真正需要读什么”。** 不要把所有 artifact 串成仪式性长链；但 task 必须依赖其实现所依据的 spec/design/review。
5. **`tasks.md` 使用标准 checkbox，并写清验证方式。** 默认 schema 明确要求 `- [ ]`，每项任务小到单次会话可完成，并在描述中写明 test/command/observable behavior。[默认 schema](https://github.com/Fission-AI/OpenSpec/blob/a0ddb60d040c61f4907436a9d91310934b1dda63/schemas/spec-driven/schema.yaml#L172-L217)
6. **每次手改后 validate；发布前冒烟。** 文件存在不等于内容正确，重要 gate 放 CI。
7. **项目级优先，提交 Git。** 解析顺序是 project → user → package；项目级 schema 能让全队得到同一份版本化工作流。[resolver 源码](https://github.com/Fission-AI/OpenSpec/blob/a0ddb60d040c61f4907436a9d91310934b1dda63/src/core/artifact-graph/resolver.ts#L120-L171)
8. **把 schema 命令当实验性接口。** 当前 CLI 自身把 `schema` 标为 experimental 并在每次操作时提示“may change”；升级 OpenSpec 后应重新跑验证与冒烟。[命令源码](https://github.com/Fission-AI/OpenSpec/blob/a0ddb60d040c61f4907436a9d91310934b1dda63/src/commands/schema.ts#L505-L515)

## 二、OpenSpec 默认工作流（以 Codex 为例）

### 2.1 安装与初始化

OpenSpec v1.11.0 需要 Node.js `>=20.19.0`。安装 CLI 后，在项目根目录为 Codex 初始化：[README](https://github.com/Fission-AI/OpenSpec/blob/a0ddb60d040c61f4907436a9d91310934b1dda63/README.md#L123-L149)

```bash
npm install -g @fission-ai/openspec@latest
cd your-project
openspec init --tools codex
```

Codex 不生成 `opsx` command files，只生成 `.agents/skills/openspec-*/SKILL.md`；调用时使用 `$openspec-...`。`openspec init` 打印的 Getting started 提示是最终权威写法。[官方工具矩阵](https://github.com/Fission-AI/OpenSpec/blob/a0ddb60d040c61f4907436a9d91310934b1dda63/docs/supported-tools.md#L24-L61) · [Codex 文件路径](https://github.com/Fission-AI/OpenSpec/blob/a0ddb60d040c61f4907436a9d91310934b1dda63/docs/supported-tools.md#L63-L76)

默认 `core` profile 的 Codex skills 是：

| 通用名称 | Codex 调用 | 作用 |
|---|---|---|
| explore | `$openspec-explore` | 在写 artifact/代码前调查问题与方案 |
| propose | `$openspec-propose` | 一次生成实现所需规划 artifact |
| apply | `$openspec-apply-change` | 按任务实现并更新 checkbox |
| update | `$openspec-update-change` | 修订现有规划 artifact，保持一致 |
| sync | `$openspec-sync-specs` | 不归档，先把 delta 合入主 specs |
| archive | `$openspec-archive-change` | 完成后同步（如选择）并归档 |

六个默认 workflow 由文档与源码共同确认。[官方列表](https://github.com/Fission-AI/OpenSpec/blob/a0ddb60d040c61f4907436a9d91310934b1dda63/docs/supported-tools.md#L12-L22) · [profile 源码](https://github.com/Fission-AI/OpenSpec/blob/a0ddb60d040c61f4907436a9d91310934b1dda63/src/core/profiles.ts#L10-L15)

不要把“安装的六个 workflow”与“常见端到端循环”混为一谈：常见循环是 **Explore（可选）→ Propose → Review → Apply → Archive** 五个人类步骤，其中 Review 不是 skill；`update`、`sync` 是按需分支，但它们仍属于默认安装的六个 workflow。

### 2.2 日常默认闭环

```text
$openspec-explore          可选：调查代码、澄清问题，不写代码/默认不写 artifact
        ↓
$openspec-propose          创建 change，按 schema 生成规划 artifact；不实现
        ↓
人工审阅                   proposal → specs → design（如需要）→ tasks
        ↓
$openspec-update-change    仅当计划需要修订
        ↓
$openspec-apply-change     读当前 artifact，逐项实现并勾选 tasks
        ↓
$openspec-sync-specs       可选：归档前先更新主 specs
        ↓
$openspec-archive-change   合并未同步 delta（经确认）并移动到 archive
```

#### 1. Explore：先理解，再承诺

模糊问题、陌生代码、存在多个实现路线时，用 `$openspec-explore`。它会读代码、比较方案和缩小范围，但不创建 change、artifact 或代码；需求已经很清楚时可跳过。[官方指南](https://github.com/Fission-AI/OpenSpec/blob/a0ddb60d040c61f4907436a9d91310934b1dda63/docs/explore.md#L1-L37)

#### 2. Propose：生成共享、可审阅的计划

```text
$openspec-propose add-rate-limiting
```

默认 `spec-driven` schema 的概念链是：

```text
proposal → specs → design → tasks → implement
   why       what      how      steps
```

`propose` workflow 明确有 planning boundary：创建规划 artifact 后停止，不在同一次调用中开始实现。[生成的官方 skill](https://github.com/Fission-AI/OpenSpec/blob/a0ddb60d040c61f4907436a9d91310934b1dda63/skills/openspec-propose/SKILL.md#L12-L24)

默认 design 并非每个小改动都必须写；内置 instruction 只在跨模块/架构、新依赖或重要数据模型、安全/性能/迁移复杂度，或需要先做技术决策时创建。[默认 schema](https://github.com/Fission-AI/OpenSpec/blob/a0ddb60d040c61f4907436a9d91310934b1dda63/schemas/spec-driven/schema.yaml#L137-L170)

#### 3. Review：人类真正签字的地方

建议按以下顺序读：

1. `proposal.md`：问题、意图、范围是否正确，有没有偷带工作。
2. `specs/**/spec.md`：完成定义是否可观察、可测试，关键边界/错误场景是否缺失。
3. `design.md`：技术选择与风险是否合理（需要 design 时）。
4. `tasks.md`：任务是否全部能追溯到需求、顺序合理、没有越界。

官方把 plan review 放在 propose 与 apply 之间，并指出最有价值的检查是发现“你忘了说、AI 因而没写”的场景。[官方 review 指南](https://github.com/Fission-AI/OpenSpec/blob/a0ddb60d040c61f4907436a9d91310934b1dda63/docs/reviewing-changes.md#L7-L19) · [审阅顺序与检查项](https://github.com/Fission-AI/OpenSpec/blob/a0ddb60d040c61f4907436a9d91310934b1dda63/docs/reviewing-changes.md#L21-L87)

计划不对时直接编辑 Markdown，或用 `$openspec-update-change` 让 Codex 修订。Artifact 是 live plan，不存在不可回退的 planning phase。[官方编辑指南](https://github.com/Fission-AI/OpenSpec/blob/a0ddb60d040c61f4907436a9d91310934b1dda63/docs/editing-changes.md#L1-L23)

#### 4. Apply：从当前文件恢复并实现

建议开一个干净 Codex 会话：

```text
$openspec-apply-change add-rate-limiting
```

Apply 会通过 CLI 取得 schema、context files、task 状态与动态 instruction，读取所有现有规划 artifact，再逐项实现；每项真正完成后立刻把 `- [ ]` 改为 `- [x]`，遇到范围外工作、设计问题、错误或歧义就暂停，不静默猜测。[官方 apply skill](https://github.com/Fission-AI/OpenSpec/blob/a0ddb60d040c61f4907436a9d91310934b1dda63/skills/openspec-apply-change/SKILL.md#L29-L103) · [guardrails](https://github.com/Fission-AI/OpenSpec/blob/a0ddb60d040c61f4907436a9d91310934b1dda63/skills/openspec-apply-change/SKILL.md#L165-L179)

计划和进度在文件而非聊天隐藏状态中，所以清空上下文后再次 apply，会读取 artifact 并从第一个未勾选任务恢复。官方也明确建议实现前清理 context window。[FAQ](https://github.com/Fission-AI/OpenSpec/blob/a0ddb60d040c61f4907436a9d91310934b1dda63/docs/faq.md#L91-L97)

#### 5. Sync / Archive：让记录与实现一致

`$openspec-sync-specs` 用于 change 仍活跃时先把 delta 合入 `openspec/specs/`，适合并行 change 需要依赖新 spec，或希望先审阅合并结果的场景；它不是每次都必须单独运行，archive 会检测 delta 并询问是否同步。[官方 OPSX 文档](https://github.com/Fission-AI/OpenSpec/blob/a0ddb60d040c61f4907436a9d91310934b1dda63/docs/opsx.md#L218-L227)

`$openspec-archive-change` 完成两件事：把 delta spec 合入主 specs（如果选择同步），再将 change 移到 `openspec/changes/archive/YYYY-MM-DD-<name>/`。归档后主 specs 描述当前系统，archive 保留“为何这样变化”的历史。[核心模型](https://github.com/Fission-AI/OpenSpec/blob/a0ddb60d040c61f4907436a9d91310934b1dda63/docs/overview.md#L11-L26)

归档前必须让 code 与 artifact 重新一致；若手工改了代码，或者实现中改变了行为，应更新 delta spec 后再归档。[官方编辑指南](https://github.com/Fission-AI/OpenSpec/blob/a0ddb60d040c61f4907436a9d91310934b1dda63/docs/editing-changes.md#L50-L59)

### 2.3 CLI 与 Codex 的职责边界

OpenSpec 不是“CLI 自动写完整计划”。实际协作是：

```text
人 → Codex skill
      ├─ 调 CLI：创建 change、读状态、解析依赖、取 instruction/template
      ├─ 写 Markdown artifact / 实现代码
      └─ 调 CLI：验证、同步状态、归档
```

CLI 提供确定性的路径、DAG、状态与模板；Codex 负责理解代码、生成 artifact、执行任务与智能合并。官方 sequence diagram 展示了 propose/apply/archive 的这条调用链。[官方工作流架构](https://github.com/Fission-AI/OpenSpec/blob/a0ddb60d040c61f4907436a9d91310934b1dda63/docs/workflows.md#L57-L98)

这个边界也解释了为什么 schema 中 instruction/template 的质量很重要，以及为何应把 `openspec validate`、测试和人工 review 保留在闭环中：CLI 可以验证结构，不能替你判断计划或实现是否正确。

### 2.4 可选扩展

`new`、`continue`、`ff`、`verify`、`bulk-archive`、`onboard` 不在默认 core profile。启用后运行 update，让项目获得新 skills：

```bash
openspec config profile
openspec update
```

Codex 对应调用例如 `$openspec-new-change`、`$openspec-continue-change`、`$openspec-verify-change`。其中 verify 在归档前从 Completeness、Correctness、Coherence 三个维度比对计划与实现，但它是报告型检查，不替代真实测试。[扩展 workflow 列表](https://github.com/Fission-AI/OpenSpec/blob/a0ddb60d040c61f4907436a9d91310934b1dda63/docs/supported-tools.md#L14-L22) · [verify skill](https://github.com/Fission-AI/OpenSpec/blob/a0ddb60d040c61f4907436a9d91310934b1dda63/skills/openspec-verify-change/SKILL.md#L42-L57)

## 三、设计哲学及最佳实践

### 3.1 设计哲学

#### Fluid, not rigid：动作，不是阶段

OpenSpec 不把人锁进“规划完才能实现、实现后不能回头”的瀑布阶段；commands 是随时可执行的动作，artifact dependencies 是“现在具备哪些上下文”的 enabler，不是组织审批 gate。[官方 workflow 哲学](https://github.com/Fission-AI/OpenSpec/blob/a0ddb60d040c61f4907436a9d91310934b1dda63/docs/workflows.md#L5-L29)

含义不是“不要顺序”，而是：默认顺序为后续 artifact 提供上下文，但实现中发现设计错误时可以直接修订 artifact，再继续。自由的代价是团队必须主动控制 scope，避免 change 膨胀。[官方解释](https://github.com/Fission-AI/OpenSpec/blob/a0ddb60d040c61f4907436a9d91310934b1dda63/docs/overview.md#L63-L71)

#### Iterative, not waterfall：文件是活的计划

需求和认知会随代码阅读、实现和测试而变化；artifact 可随时直接编辑，agent 每次从磁盘读取当前版本。相同意图下的执行细化应更新原 change；意图根本改变或 scope 爆炸时，另起 change。[官方编辑模型](https://github.com/Fission-AI/OpenSpec/blob/a0ddb60d040c61f4907436a9d91310934b1dda63/docs/editing-changes.md#L17-L36) · [update/new 判断](https://github.com/Fission-AI/OpenSpec/blob/a0ddb60d040c61f4907436a9d91310934b1dda63/docs/editing-changes.md#L71-L83)

#### Easy, not complex：plain Markdown + Git，没有隐藏状态

Change 是一个自包含目录，proposal、design、tasks、delta specs 同处一地；归档保留完整上下文。Artifact 是 plain Markdown，task 进度就是 checkbox，因此人可以直接审阅/编辑，新会话也能恢复。[官方概念](https://github.com/Fission-AI/OpenSpec/blob/a0ddb60d040c61f4907436a9d91310934b1dda63/docs/concepts.md#L182-L214) · [FAQ](https://github.com/Fission-AI/OpenSpec/blob/a0ddb60d040c61f4907436a9d91310934b1dda63/docs/faq.md#L91-L97)

#### Brownfield-first：描述差异，不重写世界

`openspec/specs/` 是当前行为的 source of truth；`changes/` 是候选修改。Change 内写 `ADDED`、`MODIFIED`、`REMOVED` delta，只描述变化；archive 才把它折叠进主 spec。这让多个 change 可并行，也无需先为旧系统补齐全部文档。[核心模型](https://github.com/Fission-AI/OpenSpec/blob/a0ddb60d040c61f4907436a9d91310934b1dda63/docs/overview.md#L11-L26) · [delta 的收益](https://github.com/Fission-AI/OpenSpec/blob/a0ddb60d040c61f4907436a9d91310934b1dda63/docs/concepts.md#L398-L406)

#### Agree first, then build confidently：轻量的人机协议层

OpenSpec 的价值不在于多写 Markdown，而在于把聊天中的模糊意图变成可审阅、可测试、随代码版本化的共同计划，在代码产生前以低成本修正误解。[官方概览](https://github.com/Fission-AI/OpenSpec/blob/a0ddb60d040c61f4907436a9d91310934b1dda63/docs/overview.md#L1-L5) · [成本/收益](https://github.com/Fission-AI/OpenSpec/blob/a0ddb60d040c61f4907436a9d91310934b1dda63/docs/overview.md#L73-L82)

### 3.2 最佳实践清单

#### 需求与 spec

- 一项 requirement 表达一个可观察行为，默认使用明确的 `SHALL`/`MUST`；不要把库、类名、表结构等实现细节写入 spec。[官方写作指南](https://github.com/Fission-AI/OpenSpec/blob/a0ddb60d040c61f4907436a9d91310934b1dda63/docs/writing-specs.md#L7-L39)
- 每个 requirement 至少一个真正验证它的 scenario；覆盖最重要的 edge/error case，而不只是 happy path。[官方写作指南](https://github.com/Fission-AI/OpenSpec/blob/a0ddb60d040c61f4907436a9d91310934b1dda63/docs/writing-specs.md#L41-L49)
- `MODIFIED` 必须给出完整的新 requirement；归档时它替换旧版本。写 delta 前先看主 spec，确认是 ADDED、MODIFIED 还是 REMOVED。[官方 delta 指南](https://github.com/Fission-AI/OpenSpec/blob/a0ddb60d040c61f4907436a9d91310934b1dda63/docs/writing-specs.md#L51-L61)
- 一个 change 只保留一个可用一句话说明的 intent；出现大量 “and also” 就拆分。极小修复则匹配风险，别强行堆满文档。[官方 right-size 指南](https://github.com/Fission-AI/OpenSpec/blob/a0ddb60d040c61f4907436a9d91310934b1dda63/docs/writing-specs.md#L63-L78)

#### 审阅与执行

- Propose 后一定读计划；最小审阅顺序是 proposal → delta specs → tasks。spec 是最高价值审阅点，关注缺失场景。[官方 review 指南](https://github.com/Fission-AI/OpenSpec/blob/a0ddb60d040c61f4907436a9d91310934b1dda63/docs/reviewing-changes.md#L21-L87)
- 先让 AI 读实际代码。问题或路线不清时 explore；已经明确时直接 propose，避免为仪式增加一步。[官方 explore 指南](https://github.com/Fission-AI/OpenSpec/blob/a0ddb60d040c61f4907436a9d91310934b1dda63/docs/explore.md#L9-L37)
- Task 小而可验证，按依赖排序；完成后立即勾选，未完全满足指定行为时不能勾选。[默认 task 指令](https://github.com/Fission-AI/OpenSpec/blob/a0ddb60d040c61f4907436a9d91310934b1dda63/schemas/spec-driven/schema.yaml#L172-L217) · [apply guardrail](https://github.com/Fission-AI/OpenSpec/blob/a0ddb60d040c61f4907436a9d91310934b1dda63/skills/openspec-apply-change/SKILL.md#L165-L179)
- 实现前开干净上下文；中断后重新 apply，从 artifact 与未勾选 task 恢复，而不是依赖旧聊天记忆。[FAQ](https://github.com/Fission-AI/OpenSpec/blob/a0ddb60d040c61f4907436a9d91310934b1dda63/docs/faq.md#L91-L97)
- 实现暴露计划问题时先更新 artifact；归档前让 code、tasks、delta spec 三者说同一件事。[官方编辑指南](https://github.com/Fission-AI/OpenSpec/blob/a0ddb60d040c61f4907436a9d91310934b1dda63/docs/editing-changes.md#L38-L59)

#### Brownfield 与团队采用

- 不要先补全整个旧代码库。选一个本来就要做的、小而真实的 change，让 specs 随实际工作自然增长。[官方 brownfield 指南](https://github.com/Fission-AI/OpenSpec/blob/a0ddb60d040c61f4907436a9d91310934b1dda63/docs/existing-projects.md#L1-L39)
- 既有 PRD/SRS 是 explore 的 source material，不宜批量机械转换成 OpenSpec spec；后者是行为优先、change-scoped 的 artifact。[官方建议](https://github.com/Fission-AI/OpenSpec/blob/a0ddb60d040c61f4907436a9d91310934b1dda63/docs/existing-projects.md#L86-L101)
- 大项目按团队自然理解的 domain 组织 spec，不提前设计完整 taxonomy；monorepo 默认一个根 `openspec/` 通常足够。[官方建议](https://github.com/Fission-AI/OpenSpec/blob/a0ddb60d040c61f4907436a9d91310934b1dda63/docs/existing-projects.md#L103-L119)
- 把 `openspec/`（包括项目 schema）提交 Git；对大代码库，在 `config.yaml context` 写真正会影响每份计划的稳定约束，不复制 agent 能从代码读到的内容。[官方 cautions](https://github.com/Fission-AI/OpenSpec/blob/a0ddb60d040c61f4907436a9d91310934b1dda63/docs/existing-projects.md#L121-L126)

#### 工具与治理

- `openspec validate` 是结构检查，不是正确性证明；配合真实测试、lint、code review 和必要的 CI gate。
- `verify` 是有用的启发式报告，但源码技能明确把 correctness 建立在 keyword search、路径分析与合理推断上，并要求不确定时降低严重度；不能把它当测试替代品。[verify heuristics](https://github.com/Fission-AI/OpenSpec/blob/a0ddb60d040c61f4907436a9d91310934b1dda63/skills/openspec-verify-change/SKILL.md#L152-L165)
- OpenSpec 推荐 high-reasoning model，并强调 context hygiene；比模型名字更可持续的实践，是 plan 与 apply 分开会话、每次从文件重建上下文。[README](https://github.com/Fission-AI/OpenSpec/blob/a0ddb60d040c61f4907436a9d91310934b1dda63/README.md#L218-L223)
- 升级 CLI 后在项目内运行 `openspec update` 刷新生成 skills；自定义规则放 `config.yaml`/schema，不直接改 OpenSpec 管理的 generated skill 文件。[更新说明](https://github.com/Fission-AI/OpenSpec/blob/a0ddb60d040c61f4907436a9d91310934b1dda63/README.md#L202-L216) · [生成文件所有权](https://github.com/Fission-AI/OpenSpec/blob/a0ddb60d040c61f4907436a9d91310934b1dda63/docs/supported-tools.md#L178-L185)

## 四、建议采用的最小落地方案

对一个使用 Codex 的既有项目，先不要自定义 schema：

```bash
npm install -g @fission-ai/openspec@latest
openspec init --tools codex
```

```yaml
# openspec/config.yaml
schema: spec-driven
context: |
  写真正会影响所有计划的技术约束与团队约定。
rules:
  tasks:
    - 每项任务写明可运行的验证方式
```

然后用一个小而真实的 change 跑完：

```text
$openspec-explore          # 仅在问题/方案不清时
$openspec-propose <name>
人工审阅 proposal/specs/[design]/tasks
$openspec-apply-change <name>   # 新会话
$openspec-archive-change <name>
```

只有当 `config.yaml` 无法表达所需变化——例如必须增加 `review.md`、删掉某个 artifact、改变文档结构或依赖图——再执行：

```bash
openspec schema fork spec-driven my-workflow
openspec schema validate my-workflow
```

这条路径最符合 OpenSpec 自身的“easy not complex”和 progressive adoption：先使用标准流程，再只定制已经被真实工作证明必要的差异。

## 一手来源索引

- [OpenSpec README（哲学、安装、用法说明）](https://github.com/Fission-AI/OpenSpec/blob/a0ddb60d040c61f4907436a9d91310934b1dda63/README.md)
- [Core Concepts at a Glance](https://github.com/Fission-AI/OpenSpec/blob/a0ddb60d040c61f4907436a9d91310934b1dda63/docs/overview.md)
- [Concepts](https://github.com/Fission-AI/OpenSpec/blob/a0ddb60d040c61f4907436a9d91310934b1dda63/docs/concepts.md)
- [Workflows](https://github.com/Fission-AI/OpenSpec/blob/a0ddb60d040c61f4907436a9d91310934b1dda63/docs/workflows.md)
- [Customization / Custom Schemas](https://github.com/Fission-AI/OpenSpec/blob/a0ddb60d040c61f4907436a9d91310934b1dda63/docs/customization.md)
- [Supported Tools / Codex](https://github.com/Fission-AI/OpenSpec/blob/a0ddb60d040c61f4907436a9d91310934b1dda63/docs/supported-tools.md)
- [Writing Good Specs](https://github.com/Fission-AI/OpenSpec/blob/a0ddb60d040c61f4907436a9d91310934b1dda63/docs/writing-specs.md)
- [Reviewing a Change](https://github.com/Fission-AI/OpenSpec/blob/a0ddb60d040c61f4907436a9d91310934b1dda63/docs/reviewing-changes.md)
- [默认 `spec-driven` schema](https://github.com/Fission-AI/OpenSpec/blob/a0ddb60d040c61f4907436a9d91310934b1dda63/schemas/spec-driven/schema.yaml)
- [Artifact runtime schema](https://github.com/Fission-AI/OpenSpec/blob/a0ddb60d040c61f4907436a9d91310934b1dda63/src/core/artifact-graph/types.ts)
- [Schema parser / graph validation](https://github.com/Fission-AI/OpenSpec/blob/a0ddb60d040c61f4907436a9d91310934b1dda63/src/core/artifact-graph/schema.ts)
- [Schema CLI implementation](https://github.com/Fission-AI/OpenSpec/blob/a0ddb60d040c61f4907436a9d91310934b1dda63/src/commands/schema.ts)
