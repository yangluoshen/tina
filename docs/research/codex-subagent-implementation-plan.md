# Codex Subagent 工作流实施计划

## 目标

把前一轮 research 中确定的 tina 三阶段 subagent 工作流落到 bundle，使目标仓库安装 tina 后可以直接使用 `$tina-propose-plan`、`$tina-propose-run`、`$tina-apply`，以及五个预设 subagent，不再手工敲长提示词。

本计划只覆盖 tina 仓库自身的修改和验证，不开始执行任何用户目标仓库的 propose/apply 流程。

## 范围

实施：

- 把现有 `$tina-propose` 改名 `$tina-propose-plan`，补充分流策略输出和下一步 `/goal` 提示。
- 新增 `$tina-propose-run`：读取已确认的 proposal-plan，启动 propose/review loop。
- 新增 `$tina-apply`：启动 implement/QA/review loop，逐 Change commit。
- 新增五个 `.codex/agents/` 预设 agent。
- 在 Target Instructions 中放一份 profile 对应的 subagent 模型矩阵。
- 更新 `install.sh`、`test.sh`、`README.md`、根 `AGENTS.md` 和必要的 `CONTEXT.md` 术语。

不实施：

- 不修改用户 `~/.codex/models.json`、`~/.codex/*.config.toml` 或任何目标仓库配置。
- 不写死 QA 的服务端口、harness 路径或浏览器工具。
- 不引入 hooks、插件或 MCP 依赖。
- 不实际运行任何用户的 research/propose/apply goal。

## 已完成的 research 结论

来源见 [codex-subagent-workflow.md](/home/yangluo/github.com/yangluoshen/tina/docs/research/codex-subagent-workflow.md)。

1. Codex 项目级自定义 agent 是 `.codex/agents/` 下的独立 TOML，必填 `name`、`description`、`developer_instructions`。角色定义与模型选择分开。
2. subagent 的 `model` 和 `model_reasoning_effort` 应由父 agent 在显式 spawn 时按 profile 选择；TOML 不写死 provider 相关模型。
3. Codex profile 是会话级，`~/.codex/<name>.config.toml` 通过 `--profile <name>` 叠加。当前 deepseek 模型目录缺少 `deepseek-v4-flash-vision-exp`，需要用户环境单独补 catalog 并验证 `max`。
4. `/goal Execute $tina-propose-run <proposal-plan>.md` 可行，但 goal 文本要同时包含 skill 调用和指向 proposal-plan 文件的标准来源。成功标准不硬编码，由 `$tina-propose-plan` 根据实际拆分设计。
5. propose 必须拆成两步：`$tina-propose-plan` 保留 grilling/confirm，`$tina-propose-run` 进入长 goal，不逐项确认。

## 目标文件与改动

```text
skills/tina-propose/                         # 重命名为 tina-propose-plan
skills/tina-propose-plan/SKILL.md            # 修改
skills/tina-propose-run/SKILL.md             # 新增
skills/tina-apply/SKILL.md                   # 新增
agents/tina-proposer.toml                    # 新增
agents/tina-proposal-reviewer.toml           # 新增
agents/tina-implementer.toml                 # 新增
agents/tina-qa.toml                          # 新增
agents/tina-code-reviewer.toml               # 新增
templates/AGENTS.md                          # 修改
install.sh                                   # 修改
test.sh                                      # 修改
README.md                                    # 修改
AGENTS.md                                    # 修改：维护规则加入 agents/ 和两个新 skill
CONTEXT.md                                   # 按需增加 Proposal Plan / Run 术语
```

`dependencies.env` 不增加任何依赖；OpenSpec 和 Matt Pocock skills 保持不变。

## 实施步骤

### 1. 重命名并改造 `tina-propose-plan`

把 `skills/tina-propose/` 改名为 `skills/tina-propose-plan/`，更新 `SKILL.md` 的 `name` 和 `description`。

保留现有调研、grilling、领域对齐、size gate、`$openspec-propose`、`$tina-change-visual` 流程。在确认拆分后，强制产出：

```text
docs/proposal-plan/<date>-<scenarios>.md
```

该文件至少包含：

- 目标 outcome。
- 按依赖排序的 Change 列表。
- 每个 Change 的单一意图。
- 依赖关系与可并行项。
- 已确认约束。
- 根据本次拆分设计的每个 Change 完成标准和总体停止条件。

成功标准由本次 grilling 结果生成，不在 skill 中写死。skill 输出末尾附下一步提示：

```text
/goal Execute $tina-propose-run docs/proposal-plan/<date>-<scenarios>.md.
Follow the success criteria and stopping condition in that file.
Do not grill, ask for individual confirmation, or archive.
```

### 2. 新增 `tina-propose-run`

`skills/tina-propose-run/SKILL.md` 只处理已确认 plan：

1. 确认目标 proposal-plan 文件存在。
2. 创建或使用 goal，目标与停止条件来自该文件，不自行发明。
3. 从 `templates/AGENTS.md` 的模型矩阵按当前 profile 选择每个 subagent 的 `model` 和 `reasoning_effort`。
4. 对每个 Change 依次 spawn `tina_proposer`，再 spawn `tina_proposal_reviewer`；不通过则把反馈回传 proposer，直到 Approved。
5. 仅在两个 Change 不共享 capability 或文件时并行；否则串行。
6. 每个 Change 的最终 review 写入 `docs/run/<change>-plan.md`。
7. 所有 Change 满足 plan 文件的停止条件后完成 goal，不 archive。

### 3. 新增 `tina-apply`

`skills/tina-apply/SKILL.md` 只处理已批准 Change：

1. 目标范围按依赖排序，逐个执行。
2. 对每个 Change 依次 spawn `tina_implementer`、`tina_qa`、`tina_code_reviewer`。
3. QA 和 review 的反馈回传 implementer 修复，直到通过。
4. 通过后检查工作树只包含该 Change 的预期文件，`git add` 并提交 `tina(change): <change-name>`。
5. concerns 和遗留问题写入 `docs/run/<change>-concerns.md`，goal 结束时提示用户。
6. 不 archive、不进入下一个 Change 前不 commit 前一个。

### 4. 新增五个 preset agent

在根目录新增 `agents/`，每个文件一个 agent。TOML 只写角色边界，不写 `model` 和 `model_reasoning_effort`。

五个 agent：

| 文件名 | `name` | 职责 |
|---|---|---|
| `tina-proposer.toml` | `tina_proposer` | 生成单个 Change 的 OpenSpec 规划 |
| `tina-proposal-reviewer.toml` | `tina_proposal_reviewer` | 独立审 proposal |
| `tina-implementer.toml` | `tina_implementer` | 实施并修复 QA/review 问题 |
| `tina-qa.toml` | `tina_qa` | 真实环境验收，只写 QA issues |
| `tina-code-reviewer.toml` | `tina_code_reviewer` | QA 后 code review |

审阅类 agent 设 `sandbox_mode = "read-only"`；implementer 和 QA 保持继承。QA 的 `developer_instructions` 只要求读取该 Change 指定的环境信息，不写死端口或 harness 路径。

### 5. 在 Target Instructions 放模型矩阵

`templates/AGENTS.md` 增加受管理区块：

```text
## Tina Subagent Models

| role | deepseek profile | openai profile |
|---|---|---|
| tina-implementer | deepseek-v4-flash / max | gpt-5.6-terra / max |
| tina-qa | deepseek-v4-flash-vision-exp / max | gpt-5.6-sol / medium |
| tina-proposer, tina-proposal-reviewer, tina-code-reviewer | deepseek-v4-pro / high | gpt-5.6-sol / high |
```

`$tina-propose-run` 和 `$tina-apply` 都引用这份矩阵，避免在两处重复维护。

### 6. 更新 `install.sh`

- 把 skill 复制列表中的 `tina-propose` 替换为 `tina-propose-plan`，并加入 `tina-propose-run`、`tina-apply`。
- 增加 `agents/` 到 `.codex/agents/` 的 `check_directory` 和 `copy_directory`。
- 保持非破坏性冲突保护，目标已有同名且内容不同的 agent 时拒绝覆盖并显示 diff。

不改动删除旧 `tina-propose`。已安装旧版本的目标仓库不会自动清理旧 skill；新 Target Instructions 指向 `tina-propose-plan`，旧目录可留给用户手动删除，避免安装器出现破坏性删除。

### 7. 更新 `test.sh`

- 断言目标项目存在 `tina-propose-plan`、`tina-propose-run`、`tina-apply`。
- 断言五个 `.codex/agents/*.toml` 存在，且每个文件含 `name`、`description`、`developer_instructions`。
- 验证重复安装幂等。
- 修改其中一个 agent 文件后再次安装应失败。
- 保留现有 OpenSpec schema 和 `change.html` 断言。

### 8. 更新文档与维护规则

- `README.md` 增加三阶段命令和 proposal-plan 路径说明。
- 根 `AGENTS.md` 维护规则加入 `agents/` 与两个新 skill 的维护要求：改后运行 `./test.sh`。
- `CONTEXT.md` 增加「Proposal Plan」「Propose Run」术语，区分规划确认和长时间执行。

## 验收标准

- `./test.sh` 在干净环境中通过。
- 安装后的目标仓库出现 `.codex/agents/` 五个 TOML 和 `.agents/skills/` 三个相关 skill。
- `templates/AGENTS.md` 的路由覆盖 `$tina-propose-plan`、`$tina-propose-run`、`$tina-apply`。
- `install.sh` 对已修改 agent 文件拒绝覆盖。
- 未改动 vendored Matt Pocock skills 和 OpenSpec schema。

## 用户环境准备（不写进 bundle）

- deepseek profile：把 `deepseek-v4-flash-vision-exp` 加进用户自己的 model catalog，标记图像输入和 `max` reasoning，并用真实截图请求验证 `max` 可用。
- openai profile：准备 `~/.codex/openai.config.toml`、OpenAI 认证和可用 catalog。
- 现有 `~/.codex/config.deepseek.toml` 如需标准 profile，可迁移为 `~/.codex/deepseek.config.toml` 并用 `codex --profile deepseek` 启动。

这些步骤属于用户环境，不由 tina installer 自动修改。

## 风险

- `/goal` 与 `$tina-propose-run` 组合没有单独官方示例；用完整 goal 文本降低歧义。
- `deepseek-v4-flash-vision-exp` 的 `max` reasoning 需实测，失败则停下报告，不降级。
- 并行 propose 可能触碰相同 capability；`$tina-propose-run` 必须做重叠检查。
- 旧 `tina-propose` 留在目标仓库可能造成两个相似 skill；Target Instructions 明确新名称，暂不自动删除。
