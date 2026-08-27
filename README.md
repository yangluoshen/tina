# Tina Workflow

Tina Workflow 是一套面向 Codex 的个人规划与编码工作流 bundle。它基于
OpenSpec，把领域模型、提案、行为规格、条件设计、任务拆解和验证组织成一条
可安装、可审阅、可重复执行的流程。

## 核心流程

```text
$tina-research（按需）
        ↓
$tina-propose
        ├── proposal.md
        ├── specs/**/*.md（有行为变化时）
        ├── design.md（按需）
        ├── tasks.md
        └── change.html（面向人类的图示摘要）
        ↓
人工审阅
        ↓
$openspec-apply-change
        ↓
$tina-verify
        ↓
$openspec-archive-change
```

主要约束：

- 一个 Change 只承载一个独立意图，最多两个 capability，约八个粗粒度任务，
  并能在一次专注实现会话中完成。
- 提案阶段默认采用中文叙事，同时保留既有标题、标识符、路径、代码和领域术语。
- 规划前读取适用的 `CONTEXT.md`、`CONTEXT-MAP.md` 和 ADR，保持领域语言一致。
- `change.html` 从 `proposal.md` 和可选的 `design.md` 派生，以 software diagram
  为主帮助人类快速决策；Markdown 始终是权威来源。
- 实现、验证和归档是三个独立动作，不自动越过人工授权。

## 前置条件

- Git
- Node.js 与 npm
- Codex
- 与本 bundle pin 一致的 OpenSpec CLI

在 bundle 根目录安装对应版本的 OpenSpec：

```sh
. ./dependencies.env
npm install -g "$OPENSPEC_PACKAGE@$OPENSPEC_VERSION"
```

## 安装到目标仓库

在本仓库根目录执行；目标目录不存在时，安装器会连同缺失的父目录一起创建：

```sh
./install.sh /absolute/path/to/target-repository
```

安装器会：

- 运行 `openspec init --tools codex`；
- 安装 `tina-*` 私有 skill 和固定版本的 Matt Pocock skills；
- 安装项目级 `tina` schema，并将其设为默认 schema；
- 把 Target Instructions 作为受管理区块追加到目标仓库的 `AGENTS.md`；
- 验证实际解析到的 schema。

安装是非破坏性的。相同内容可以重复安装；如果目标 skill、schema 或受管理的
`AGENTS.md` 区块已被修改，安装器会拒绝覆盖并显示差异。目标仓库原有内容不会被
静默替换。

## 日常使用

### 1. 调研（按需）

遇到陌生 API、版本敏感事实或可行性问题时：

```text
$tina-research <问题>
```

调研只使用高可信的一手来源，并把结论保存为带引用的 Research Note。

### 2. 创建 Change

```text
$tina-propose <要实现的变化>
```

该流程会完成必要的调研、grilling、领域对齐和规模检查，再调用 OpenSpec 生成规划
产物，最后生成同目录的 `change.html`。小改动可以跳过 `design.md`，但不能跳过
Proposal 的范围和能力影响说明；没有行为级 capability delta 时会设置
`skip_specs: true`，而不是虚构 requirements。

### 3. 人工审阅

先打开 `change.html` 快速理解核心思想和图示，再以 Markdown 源文件完成正式审阅：

1. `proposal.md`：问题、意图和范围是否正确；
2. `specs/**/*.md`（存在时）：行为与边界是否可观察、可测试；
3. `design.md`：技术选择、替代方案和风险是否合理；
4. `tasks.md`：任务是否有依赖顺序和明确验证方式。

### 4. 实现、验证与归档

```text
$openspec-apply-change <change-name>
$tina-verify <change-name>
$openspec-archive-change <change-name>
```

只有用户明确授权后才进入实现；归档同样需要单独请求。

## 安装后的主要文件

```text
target-repository/
├── AGENTS.md
├── .agents/skills/
│   ├── openspec-*/
│   ├── tina-research/
│   ├── tina-propose/
│   ├── tina-change-visual/
│   ├── tina-verify/
│   └── research、grilling、domain-modeling 等固定上游 skill
└── openspec/
    ├── config.yaml
    └── schemas/tina/
        ├── schema.yaml
        └── templates/
```

## 仓库结构

```text
schema/tina/               Tina OpenSpec schema 与模板
skills/tina-*/             本仓库维护的私有编排 skill
vendor/mattpocock-skills/  固定 revision 的未修改上游快照
templates/AGENTS.md        安装到目标仓库的 Target Instructions
dependencies.env          已验证的唯一依赖 pin 来源
install.sh                 非破坏性安装器
test.sh                    安装与 schema smoke test
update-dependencies.sh     唯一支持的依赖更新入口
```

根目录的 `AGENTS.md` 只约束本 bundle 的维护，不能复制到目标项目；目标项目使用
`templates/AGENTS.md`。

## 验证

修改 schema、skill、Target Instructions 或安装器后运行：

```sh
./test.sh
```

测试会在系统临时目录安装两次 workflow，验证幂等性、冲突保护、schema、动态指令
和 `change.html` 模板。

## 更新依赖

只能通过更新脚本刷新固定上游快照和依赖 pin：

```sh
./update-dependencies.sh <matt-ref> <openspec-version>
```

只有在明确测试最新上游时才使用：

```sh
./update-dependencies.sh main latest
```

更新完成后运行 `./test.sh`，并在提交前审阅完整 dependency diff。脚本使用隔离的
`npx` 验证 OpenSpec，不会修改全局 OpenSpec 安装。
