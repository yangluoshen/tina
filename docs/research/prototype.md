# Matt Prototype Skill 与 Tina 规划后原型确认

> 研究日期：2026-09-15。核对用户指定的上游入口、Tina 当前依赖 pin，以及当日 `main`；以下区分上游事实与 Tina 集成建议。

## 结论

建议引入未修改的 Matt `$prototype`，由私有 `$tina-prototype` 在 `$tina-propose-plan` 完成 grilling 和规划之后、`$tina-propose-run` 之前负责原型制作与确认。上游已经提供逻辑和 UI 两种原型，不需要 Tina 另造原型生成方法；Tina 只需补上确认记录、规划交接和生产实现边界。[上游入口](https://github.com/mattpocock/skills/blob/6654f6b60cd9d5be8b54c6fafe44346dabeb3b76/skills/engineering/prototype/SKILL.md)

## 已核实的上游事实

### 依赖范围

Tina 的现有 Matt pin 为 `6654f6b60cd9d5be8b54c6fafe44346dabeb3b76`，该 revision 已包含完整 `skills/engineering/prototype/`。2026-09-15 查询到的 `main` 为 `3cca18b368ae95cdbdebbff572ccafa662551015`；从 GitHub raw 下载两个 revision 的以下三个文件，逐字节比较均相同。因此这次引入无需升级 Matt pin。[Tina pins](../../dependencies.env) · [固定版本目录](https://github.com/mattpocock/skills/tree/6654f6b60cd9d5be8b54c6fafe44346dabeb3b76/skills/engineering/prototype) · [核对的 main 快照](https://github.com/mattpocock/skills/tree/3cca18b368ae95cdbdebbff572ccafa662551015/skills/engineering/prototype)

| 文件 | 职责 | 当前 pin 的 SHA-256 |
|---|---|---|
| `SKILL.md` | 根据待确认问题选择逻辑或 UI 分支，规定共同生命周期 | `714de632d116bb73f65cdb5a882db15b9369a6713b9a47c0fad827848f0bfbe3` |
| `LOGIC.md` | 可交互的逻辑与状态模型原型 | `f61c7d249e786a79ef289018901c348271e1798dd0b0bc5607b5c6f4d4a01ab9` |
| `UI.md` | 同一路由上的界面变体与选择器 | `723211e878acbc7b6ff09755263f3295cde724ba902ff0064da41eed51d45ad3` |

不能只复制 `SKILL.md`：入口通过相对链接加载另外两份文件。[分支链接](https://github.com/mattpocock/skills/blob/6654f6b60cd9d5be8b54c6fafe44346dabeb3b76/skills/engineering/prototype/SKILL.md)

### 原型行为

| 分支 | 上游要求 |
|---|---|
| 逻辑 | 单个自包含 HTML，双击可运行；逻辑与 DOM 分开，展示完整相关状态；提供自由操作和分场景引导，覆盖正常、边界及非法操作，用领域语言表达。 |
| UI | 默认三个、最多五个结构不同的变体；优先嵌入已有页面，用 `?variant=` 与底部选择器切换；沿用组件和路由惯例，键盘切换避开正在编辑的输入框，写操作使用 stub。 |

来源：[LOGIC.md](https://github.com/mattpocock/skills/blob/6654f6b60cd9d5be8b54c6fafe44346dabeb3b76/skills/engineering/prototype/LOGIC.md) · [UI.md](https://github.com/mattpocock/skills/blob/6654f6b60cd9d5be8b54c6fafe44346dabeb3b76/skills/engineering/prototype/UI.md)

上游把原型定义为用于回答问题的一次性代码：明确标记、就近放置、默认内存状态、无需完整测试或抽象。收尾时要求记录问题与结论，把原型保存在独立临时分支并留下引用，同时将确认的决定吸收到真实代码。[生命周期规则](https://github.com/mattpocock/skills/blob/6654f6b60cd9d5be8b54c6fafe44346dabeb3b76/skills/engineering/prototype/SKILL.md)

## Tina 集成建议

以下是针对本次目标的兼容策略，属于 Tina 私有规则，不是上游已经提供的能力。阶段顺序按用户修正：先通过 grilling 澄清预期并确认计划，再制作原型。

### 阶段与确认

```text
tina-research → tina-propose-plan（grilling + 确认计划）→ tina-prototype → 确认结论 → tina-propose-run
```

`$tina-prototype` 读取已经通过 grilling 确认的 Proposal Plan、其中引用的 Research Note、原始请求和相关代码，从用户故事、验收条件和约束中确定需要原型回答的问题，再加载 `$prototype` 及对应分支。给出可运行文件或 URL，让用户反馈并迭代；确认的对象应是具体产物及其回答的问题，不能把生成成功当作确认。

只读调查或纯文档修改如果没有可验证的逻辑/UI 问题，可以记录具体跳过理由后继续；用户明确要求 prototype 的任务必须制作并确认。已有当前范围的确认记录时直接复用。若原型反馈改变用户故事、验收条件、约束或 Change 拆分，返回 `$tina-propose-plan` 修订并确认计划，再重新验证原型；分配给 proposer 的单个 Change 不应重复整套请求级确认。

Tina 当前 research wrapper 要求显式传递 Research Note，propose-plan 只授权规划；因此 prototype 允许的写入应限定为一次性验证产物。上游“吸收到真实代码”的收尾必须延后到已授权的实现阶段，不应因用户选中了一个 UI 变体就提前修改生产行为。[research 边界](../../skills/tina-research/SKILL.md) · [planning 边界](../../skills/tina-propose-plan/SKILL.md)

### 最少持久化内容

沿用仓库的文档式交接，增加一份 Prototype Note，例如 `docs/prototypes/<date>-<scope>.md`，记录：

- 原始问题、Research Note 路径、所选分支；
- 原型的运行方式及可复现引用，包括原型文件或保留分支；
- 用户确认的状态规则/变体和理由，以及明确的未解决问题；
- 确认来源与时间；跳过时记录适用理由。

Proposal Plan 在 grilling 后先记录待验证问题和 `pending` 状态；原型确认后补充此记录与已确认约束，才进入 propose-run。确认后改变了原型要回答的问题，便需要修订计划、更新原型记录和重新确认；不需要因此新增 OpenSpec artifact 或改变 schema DAG。Tina 的 schema 仍只负责 proposal、specs、条件 design、tasks。[维护要求](../../AGENTS.md)

YOLO 已明确使用模型决策替代人工确认；新增阶段需要沿用这一例外，记录 `model-decided (tina-yolo)`，不能伪造用户确认，也不能因为加入原型阶段而破坏自主执行约定。[YOLO 规则](../../skills/tina-yolo/SKILL.md) · [Target Instructions](../../templates/AGENTS.md)

### 分发与验证

扩展现有 updater，按当前 pin 原样选取三个上游文件；安装器同时纳入 `prototype` 与 `tina-prototype` 的冲突检查和复制列表。继续使用现有 init/sync/remove payload 机制，无需另加下载器或原型 agent preset。[updater](../../update-dependencies.sh) · [installer](../../install.sh)

完成后运行 `./test.sh`，至少验证目标项目获得三个相对链接依赖文件和 Tina wrapper，并维持重复安装及冲突保护。上游“不写原型测试”针对一次性原型产物，不免除 Tina bundle 本身的安装与分发检查。[现有 smoke test](../../test.sh) · [维护要求](../../AGENTS.md)
