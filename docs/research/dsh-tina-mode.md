# DSH Tina Mode：Agent Preset 集成研究

研究日期：2026-09-17。DSH 本地源码：`/Users/shenweimin/github.com/deepseek-ai/deepseek-harness`，HEAD `0d1f50007f9bca3f52b06e1c3074fa14d5fb0720`，研究开始时 `git status --short` 为空。Tina HEAD：`472134d585c88e62607061cfa0b0e77563c0107d`。本文描述该源码快照，不代表已发布版本的兼容承诺；配置示意与集成建议尚未实现。文中绝对路径指向本机这两个 checkout；对外分享时应转换为对应 commit 的源码链接。

**建议以 DSH Web 的 `standard` preset 为基础，制作独立 `tina` preset：用 persona 保留常驻工作流规则，用 skill 按需加载阶段步骤，用 continuable subagent 承载 Tina 角色，继续以 OpenSpec 文件和 Tina run record 保存工作流状态。第一版不需要新的 workflow engine。** 主要缺口是 Codex 角色配置的适配、审核角色权限、DSH plan mode 与 Tina 产物写入的冲突，以及模式级安装隔离。

## 1. Preset 是插件组合，能力取决于 Host

| 机制 | 源码确认的行为 | Tina 的结合点 |
| --- | --- | --- |
| Preset 目录 | 目录名是 id；`agent.cordis.yml` 为插件行列表，`preset.yml` 仅放 name、description、order | `tina/preset.yml` 显示 `Tina Mode`，组合文件装配规则和工具 |
| 发现 | 内置 root → 配置 roots → `<dshHome>/.agent-presets`；先出现的同名 id 胜出 | 使用独立 id `tina`，不要用 `standard` 覆盖内置项 |
| 作用域 | 同一 preset 共享 standing composition，Session 状态独立；服务需放入正确 isolate realm | 保留 standard 的分组和 realm，仅替换必要行 |
| 创建/编辑 | 原生 authoring 是完整目录 copy；后续直接编辑文件，无 `extends: standard` 增量继承 | 从已验证的 standard 复制；升级时审查上游组合差异 |
| 生效 | 已有 session 不随文件变化切换组合；只有空白 session 可切 preset；新 generation 由组合文件 stamp 驱动 | 更新后开新会话；涉及初始化读取的旁置资产变更应同步触碰组合文件或重启 |
| Host 边界 | sandbox、approval、持久化、模型路由、subagent registry 等属于 Host | `Tina Mode` 不能仅靠 agent YAML 安装模型、提高权限或添加 Host provider |

来源：[discovery.ts:1](/Users/shenweimin/github.com/deepseek-ai/deepseek-harness/packages/preset/agent-presets/src/discovery.ts:1)、[metadata.ts:24](/Users/shenweimin/github.com/deepseek-ai/deepseek-harness/packages/preset/agent-presets/src/metadata.ts:24)、[roots 配置与优先级:107](/Users/shenweimin/github.com/deepseek-ai/deepseek-harness/packages/preset/agent-presets/src/index.ts:107)、[generation:410](/Users/shenweimin/github.com/deepseek-ai/deepseek-harness/packages/preset/agent-presets/src/index.ts:410)、[standard 的 Host/Agent 边界:1](/Users/shenweimin/github.com/deepseek-ai/deepseek-harness/packages/preset/agent-presets/presets/standard/agent.cordis.yml:1)、[authoring 与限制](/Users/shenweimin/github.com/deepseek-ai/deepseek-harness/packages/preset/agent-presets/README.md:81)。

**Web 和 CLI 不能混为一谈。** Web 已有新会话 mode picker、默认项设置、复制和删除界面，可直接承载 Tina Mode。[Web preset UI](/Users/shenweimin/github.com/deepseek-ai/deepseek-harness/packages/client/ui-agent-preset/README.md:35)

`dsh --profile ...` 选择的是启动 Host 的 profile，不是 agent preset；launcher 将后续参数交给 app。当前 one-shot headless bundle 明确没有 preset roster，并拒绝接管记录了 preset 的会话。因此本研究不提供未经验证的 `dsh --agent-preset tina` 或 `dsh --profile tina` 命令。CLI 集成需先选定具体 app/profile 并验证其 session 创建路径；首版建议 Web。[CLI 参数:1](/Users/shenweimin/github.com/deepseek-ai/deepseek-harness/apps/cli/src/args.ts:1)、[headless 拒绝 preset session:211](/Users/shenweimin/github.com/deepseek-ai/deepseek-harness/packages/bundle/headless/src/index.ts:211)、[headless composition:334](/Users/shenweimin/github.com/deepseek-ai/deepseek-harness/packages/bundle/headless/src/index.ts:334)

## 2. System prompt：优先组合 persona，不做完整覆盖

`@deepseek-ai/dsh-persona` 已提供四个字段：

| 字段 | 行为 | 建议 |
| --- | --- | --- |
| `prefix` | shadow 当前 scope 的 `deployment:persona-prefix`；支持严格 `{{…}}` 变量插值 | 简短声明 Tina 主协调者身份 |
| `suffix` | 放在 first-party guidance 后；省略/空字符串会清掉 deployment suffix | 放工作流路由、授权边界、恢复方法和角色分工等共同规则 |
| `complete` | `true` 时 prefix 成为完整 system prompt，抑制 suffix 和所有其他 section | 保持 `false`，否则现有工具指导也会消失 |
| `includeRuntimeContext` | `false` 时抑制该 scope 的 runtime-context snapshots | 保持 `true`，保留运行环境和动态上下文 |

来源：[persona Config 与注册:29](/Users/shenweimin/github.com/deepseek-ai/deepseek-harness/packages/preset/persona/src/index.ts:29)，对应测试：[完整覆盖:126](/Users/shenweimin/github.com/deepseek-ai/deepseek-harness/packages/preset/persona/tests/persona.spec.ts:126)、[runtime context:143](/Users/shenweimin/github.com/deepseek-ai/deepseek-harness/packages/preset/persona/tests/persona.spec.ts:143)。

更细粒度的插件可通过 `ctx.systemPrompt.section()` 注册命名段、通过 `context()` 提供动态上下文。**第一版 suffix 已足够；只有需要读取当前 Change、阶段、授权记录并动态展示时，再增加 Tina 插件。** 这是设计取舍，不是 DSH 已有 Tina 状态能力。[section/context 接口](/Users/shenweimin/github.com/deepseek-ai/deepseek-harness/packages/core/system-prompt/src/index.ts:1)

角色覆盖还有一个具体影响：DSH 子 agent 的 `persona` 只覆盖 prefix；如果将全部 Tina 规则写在父 prefix，角色会替换掉这些规则。将共同规则放 suffix、角色职责放子 persona，可以复用现有 scope 层次。[child composition:200](/Users/shenweimin/github.com/deepseek-ai/deepseek-harness/packages/subagent/subagent/src/child-agent.ts:200)

## 3. Skills：现有 `.agents/skills` 可读，但不要假设 Codex 调用语法等价

`skill-filesystem` 默认发现项目 `.dsh/skills`、项目 `.agents/skills`、自定义目录、DSH 用户目录和共享 `.agents` 用户目录；还有 bundled root。配置支持 `providerName`、`includeDefaultRoots`、`customSkillDirs` 等，preset 内可用 `baseUrl` 定位随 preset 复制的 `skills/`。这让 Tina 的目录型 `SKILL.md` 有直接复用入口。[默认 roots:245](/Users/shenweimin/github.com/deepseek-ai/deepseek-harness/packages/skill/skill-filesystem/src/index.ts:245)、[配置:48](/Users/shenweimin/github.com/deepseek-ai/deepseek-harness/packages/skill/skill-filesystem/src/index.ts:48)、[内置 cordis 的旁置 skills 范例:256](/Users/shenweimin/github.com/deepseek-ai/deepseek-harness/packages/preset/agent-presets/presets/cordis/agent.cordis.yml:256)

默认 roots 中，项目 `.dsh/skills`、`.agents/skills` 的优先级高于 `customSkillDirs`，因此项目同名 skill 可以覆盖随 preset 分发的版本。上面的复用入口不保证固定版本隔离；若需要固定 Tina bundle，应明确选择独立 provider 的 roots 策略，并验证与其他 provider 的合并结果。[roots rank:38](/Users/shenweimin/github.com/deepseek-ai/deepseek-harness/packages/skill/skill-filesystem/src/index.ts:38)

调用有两条路径：

- **模型按需加载**：`skill({ name })` 返回正文及 `resourceBase`。catalog 只包含摘要；工具描述要求在命中 skill 时先加载。模型不得调用 `disable-model-invocation: true` 的 skill。[tool-skill:81](/Users/shenweimin/github.com/deepseek-ai/deepseek-harness/packages/skill/tool-skill/src/index.ts:81)
- **用户显式调用**：直接 user message 的任意文本位置中，以空白或文本边界分隔的 `/<name>` 会被确定性识别，正文作为 instructions context 注入。外部文本不能伪造这个入口。`user-invocable: false` 禁止用户调用；默认两种调用都开启。[调用匹配实现:403](/Users/shenweimin/github.com/deepseek-ai/deepseek-harness/packages/skill/tool-skill/src/index.ts:403)、[frontmatter 解析:1000](/Users/shenweimin/github.com/deepseek-ai/deepseek-harness/packages/skill/skill-filesystem/src/index.ts:1000)

**建议**：DSH 用户入口使用 `/tina-research`、`/tina-yolo` 等实际 skill 名；wrapper 内将 `$tina-*` 理解/适配为精确 `skill` 调用，不声称 `$` 是 DSH 原生确定性入口。已有 vendored skill 保持原样，在 Tina 私有 wrapper 或 DSH 适配说明处理工具名和调用约定。

技能被加载不等于规则被执行。catalog/skill 本身不保证独立 QA、固定 reviewer、P0 修复或 archive 授权。显式 skill 入口也不能代替“当前请求是否授予 YOLO 权限”的判断；该约束仍需 Tina policy/run record 表达。

## 4. Subagent：原生支持角色工具和持久 child，尚无 Codex TOML 自动转换

| 需求 | DSH 已有机制 | 限制/适配 |
| --- | --- | --- |
| Tina 角色 | 多个 `dsh-tool-subagent` 行，各自唯一 `toolName`、固定 `persona` | 这是角色工具，不是给每个 child 选择另一个 agent preset |
| 模型与 effort | `agentOptions.provider/model/reasoningEffort/maxTokens`；可选 Host model-selection settings | 路由需实际可用；Codex 的模型名不能直接视为 DSH 路由 |
| 工具权限 | `toolFilter.allow/deny` 从 schema 隐藏并阻止执行；未知工具名在启动时失败 | 不是独立 OS sandbox；保留 shell/PTC 等可能仍能写文件 |
| 同一个 proposer/reviewer 反复工作 | `backgroundMode: continuable` 返回 durable child id，`send_message` 可继续该 child | 保存 child id 到 run record；使用 direct parent/child 通信 |
| 新上下文/继承上下文 | Host 提供 `spawn` 和 `fork`；standard 默认都可继续 | QA/review 优先 spawn，减少继承实现者历史；这是 Tina 设计选择 |
| 限制递归 | `maxDepth` 默认 3，0 禁止该工具继续委派 | 角色有多少层需与 Tina 实际调用链核对 |

来源：[tool-subagent Config:48](/Users/shenweimin/github.com/deepseek-ai/deepseek-harness/packages/subagent/tool-subagent/src/index.ts:48)、[子 agent 选项继承:88](/Users/shenweimin/github.com/deepseek-ai/deepseek-harness/packages/subagent/subagent/src/child-agent.ts:88)、[standard 委派配置:158](/Users/shenweimin/github.com/deepseek-ai/deepseek-harness/packages/preset/agent-presets/presets/standard/agent.cordis.yml:158)、[sendMessage:231](/Users/shenweimin/github.com/deepseek-ai/deepseek-harness/packages/subagent/subagent/src/index.ts:231)。

**不要把 `agent preset` 和 Tina 的 `agents/tina-*.toml` 视为同一种 preset。** DSH `SubagentStartRequest` 接受 persona/options/filter，没有 `agentPreset` 选择字段；in-process child 调用 `composeFrom(childCtx, parent.ctx)` 加入父 preset。已检查的发现路径没有导入 `.codex/agents/*.toml`。需要显式转换角色职责与模型配置，并核对 sandbox 语义。[StartRequest:145](/Users/shenweimin/github.com/deepseek-ai/deepseek-harness/packages/subagent/subagent/src/types.ts:145)、[composeFrom:200](/Users/shenweimin/github.com/deepseek-ai/deepseek-harness/packages/subagent/subagent/src/child-agent.ts:200)、[preset inheritance 测试:70](/Users/shenweimin/github.com/deepseek-ai/deepseek-harness/packages/subagent/subagent-in-process-driver/tests/preset-inheritance.spec.ts:70)

尤其不能把 Tina reviewer 的 `sandbox_mode = "read-only"` 静默降级成“提示它别写”。DSH 这里继承父权限并固定子审批范围，角色工具 Config 没有独立 `sandboxMode` 字段。可选首版方案是只允许已核对的只读工具，必要测试由主 agent 执行；若角色必须运行任意 shell 测试，就需另行验证 Host 级只读执行隔离。`deny: [write, edit]` 而保留 shell 不满足只读要求。[工具配置字段:48](/Users/shenweimin/github.com/deepseek-ai/deepseek-harness/packages/subagent/tool-subagent/src/index.ts:48)、[delegated policy:221](/Users/shenweimin/github.com/deepseek-ai/deepseek-harness/packages/subagent/subagent/src/child-agent.ts:221)

原生 `send_message` 提供继续协作能力；这里没有证明一个能够自动执行 Tina 阶段门禁的 handoff 引擎。主协调者仍负责收集结果、复用同一角色、决定下一阶段。[control tools:24](/Users/shenweimin/github.com/deepseek-ai/deepseek-harness/packages/subagent/tool-subagent-control/src/index.ts:24)

## 5. Goal、workflow、hooks、guards 的适用边界

| 机制 | 可以做什么 | 对 Tina 的选择 |
| --- | --- | --- |
| Goal | 同一 session 的持久完成目标与自动续轮；create/update 有人类来源和子 agent 权限校验 | 可承载明确授权的长任务续跑；不能把“进入 Tina Mode”视为 YOLO、archive 或无限执行授权 |
| workflow-ptc | JS 编排 `agent`、`parallel`、`pipeline`，有并发/总数上限、结构化输出 | 暂不作为 Tina 主状态机；继续使用 OpenSpec 与 run record |
| Codex hooks bridge | 五类事件：PreToolUse、PostToolUse、SessionStart、UserPromptSubmit、Stop；同步 command hook | 已有脚本可复用时使用；不是自动读取全部 Codex 配置 |
| Cordis 事件 | `agent/pre-step` 可注入/拒绝；`tools/pre-execute` 可干预工具调用 | 真正需要阶段检查时可写小 Tina policy 插件 |
| `tools.guard()` | 在 pre-execute 后、工具体前执行，只能 deny，不能重新 allow | 适合约束明确工具入口；不能仅靠命令字符串匹配封住所有 shell 写入/归档途径 |

来源：[goal tool:24](/Users/shenweimin/github.com/deepseek-ai/deepseek-harness/packages/goal/tool-goal/src/index.ts:24)、[goal round driver:111](/Users/shenweimin/github.com/deepseek-ai/deepseek-harness/packages/goal/goal-round-driver/src/index.ts:111)、[workflow runtime:33](/Users/shenweimin/github.com/deepseek-ai/deepseek-harness/packages/workflow/workflow-ptc/src/runtime.ts:33)、[hooks 配置支持范围:1](/Users/shenweimin/github.com/deepseek-ai/deepseek-harness/packages/hooks/hooks-codex/src/config.ts:1)、[tools guard:1106](/Users/shenweimin/github.com/deepseek-ai/deepseek-harness/packages/core/tools/src/index.ts:1106)。

三个会影响方案的细节：

1. `workflow-ptc` 的 `agent()` 仅接受 label、phase、schema、provider、model；effort、isolation、agentType 明确 deferred。每次 agent run 在结果后 dispose；`pipeline()` 是逐 item 的 stage 链，没有全局阶段 barrier。原生 `agent()` 生命周期不适合 Tina“同一个 reviewer 多轮修复”的要求。“全部 Change 提案完成后才全局 review”可以通过先等待并行提案结束、再启动 review 表达，但不能直接依赖 `pipeline()` 提供这个等待点。[runtime:33](/Users/shenweimin/github.com/deepseek-ai/deepseek-harness/packages/workflow/workflow-ptc/src/runtime.ts:33)、[dispose:224](/Users/shenweimin/github.com/deepseek-ai/deepseek-harness/packages/workflow/workflow-ptc/src/runtime.ts:224)、[pipeline:310](/Users/shenweimin/github.com/deepseek-ai/deepseek-harness/packages/workflow/workflow-ptc/src/runtime.ts:310)
2. Codex bridge 的 hooks 文件在加载时读取，路径相对进程 cwd；per-session project discovery 仍是 TODO。PreToolUse 只接受阻止语义，没有 allow/ask/rewrite；Stop 的 `stop_hook_active` 固定 false，无条件阻止会导致持续续跑。因此不要用无条件 Stop hook 实现 Tina YOLO。[configPath:43](/Users/shenweimin/github.com/deepseek-ai/deepseek-harness/packages/hooks/hooks-codex/src/index.ts:43)、[hook handlers:223](/Users/shenweimin/github.com/deepseek-ai/deepseek-harness/packages/hooks/hooks-codex/src/index.ts:223)
3. DSH goal 当前允许根据直接用户长任务推断创建意图，Tina 的 YOLO 则要求本次请求授权。两者语义不相同；Tina suffix 应明确自动续跑不得扩大原请求范围。[goal 创建描述:44](/Users/shenweimin/github.com/deepseek-ai/deepseek-harness/packages/goal/tool-goal/src/index.ts:44)、[Tina YOLO:6](/Users/shenweimin/github.com/tina-workflow/skills/tina-yolo/SKILL.md:6)

Goal 工具契约也不能照搬 Codex：DSH `update_goal` 要求先 `get_goal`，提交精确 `goal_id`、`revision` 与 `action: edit/pause/resume/complete/blocked`；预算字段是 `max_goal_rounds`，没有此处 Codex 的 `token_budget`。恢复/fork 后 active goal 为 disarmed，需要有相应用户继续意图再 resume。[goal activation:248](/Users/shenweimin/github.com/deepseek-ai/deepseek-harness/packages/goal/goal/src/index.ts:248)这些差异应写入 DSH wrapper。[goal guidance:111](/Users/shenweimin/github.com/deepseek-ai/deepseek-harness/packages/goal/tool-goal/src/index.ts:111)、[工具参数:207](/Users/shenweimin/github.com/deepseek-ai/deepseek-harness/packages/goal/tool-goal/src/index.ts:207)

## 6. Plan mode、压缩和恢复

**Tina 的规划阶段不能直接映射为 DSH `/plan`。** standard 的 plan mode 明确禁止写文件，而 Tina 规划/原型阶段需要产出 proposal plan、领域模型、架构记录或原型。首版在普通执行会话使用 Tina 的阶段规则；若产品需要 DSH plan UI，就需单独设计哪些文件可写及审批语义，不能假设默认兼容。[standard plan-mode:101](/Users/shenweimin/github.com/deepseek-ai/deepseek-harness/packages/preset/agent-presets/presets/standard/agent.cordis.yml:101)、[Tina propose-run 输入与产物:10](/Users/shenweimin/github.com/tina-workflow/skills/tina-propose-run/SKILL.md:10)

DSH 压缩保留 system head，将选中历史区域替换成摘要；skill catalog 会依据持久日志和当前可见 surface 判断是否需要重新发布。**catalog 可重建，不意味着此前加载的每个 skill 正文或 Tina 工作流决定都会原样保留。** 恢复协议应要求重读 run record、当前 Change、当前阶段 skill，再决定动作；不要把当前阶段只存于对话。[压缩选择:119](/Users/shenweimin/github.com/deepseek-ai/deepseek-harness/packages/compaction/compaction-basic/src/region.ts:119)、[catalogHistory:361](/Users/shenweimin/github.com/deepseek-ai/deepseek-harness/packages/skill/tool-skill/src/index.ts:361)、[catalog 注入:220](/Users/shenweimin/github.com/deepseek-ai/deepseek-harness/packages/skill/tool-skill/src/index.ts:220)

## 7. Tina 需求映射与最小设计

| Tina 现有要求 | 建议归属 |
| --- | --- |
| 阶段路由、每次请求的 YOLO 范围、archive 单独授权 | preset suffix 常驻规则 |
| research / propose / prototype / apply / QA / review / verify 步骤 | 现有私有 Tina skills，加 DSH 调用适配 |
| 同一 proposer 和全局 reviewer 的修复循环 | 独立角色工具 + continuable child id + run record |
| 仅对互不冲突的文件/能力并行；独立 QA/review | 主协调者技能规则与角色分工；必要时再添加程序化门禁 |
| proposal / specs / conditional design / tasks | 保持 Tina OpenSpec schema 与 CLI，不复制为 DSH 私有状态 |
| 恢复工作与审计 | 现有 proposal plan/run record 保存 scope、角色 id、Change、证据、审批和 issue 状态 |

Tina 来源：[Target Instructions](/Users/shenweimin/github.com/tina-workflow/templates/AGENTS.md:1)、[propose-run:24](/Users/shenweimin/github.com/tina-workflow/skills/tina-propose-run/SKILL.md:24)、[YOLO run record:24](/Users/shenweimin/github.com/tina-workflow/skills/tina-yolo/SKILL.md:24)、[schema](/Users/shenweimin/github.com/tina-workflow/schema/tina/schema.yaml:1)。上表为设计建议，DSH 不会自动强制其中的 Tina 业务规则。

建议分发结构：

```text
<dshHome>/.agent-presets/tina/
  preset.yml             # name: Tina Mode
  agent.cordis.yml        # 从该版本 standard 完整复制后定点修改
  skills/                # Tina wrappers 与依赖，保留来源和 pins
```

下面仅展示需修改/增加的行，**不是可独立运行的完整 preset，也不是 DSH 支持的 patch 文件**。复制 standard 后保留其原有工具、realm、Host 依赖关系。

```yaml
- id: persona
  name: '@deepseek-ai/dsh-persona'
  config:
    prefix: You are the Tina workflow coordinator, powered by {{model}}.
    suffix: |
      Your working directory is {{cwd}}.
      Follow the Tina stage routing and load the exact stage skill before acting.
      Recover the active run from its plan, run record, and OpenSpec artifacts.
      YOLO authority applies only to the current explicitly delegated task.
      Archiving requires its own authorization.
    complete: false
    includeRuntimeContext: true

- id: skill-filesystem
  name: '@deepseek-ai/dsh-skill-filesystem'
  config:
    customSkillDirs:
      - !!js "process.getBuiltinModule('node:url').fileURLToPath(new URL('skills/', baseUrl))"

# Add under the existing delegation group; complete role prose still needed.
- id: tina-proposer
  name: '@deepseek-ai/dsh-tool-subagent'
  config:
    provider: spawn
    toolName: tina_proposer
    backgroundMode: continuable
    persona: |
      You are the Tina proposer for one assigned Change.
      Load the Tina proposal skill and follow the assigned-Change path.
      Preserve the confirmed plan and return artifact paths and remaining issues.
```

示意仅使用已核实字段。[persona schema:49](/Users/shenweimin/github.com/deepseek-ai/deepseek-harness/packages/preset/persona/src/index.ts:49)、[subagent schema:105](/Users/shenweimin/github.com/deepseek-ai/deepseek-harness/packages/subagent/tool-subagent/src/index.ts:105)。完整角色职责应来自 Tina 自有角色文件，模型路由与 reviewer 权限验证完成后再填入；当前片段不能作为生产 Tina 行为规格。

## 8. 下一步实施范围与验收

建议首个实施切片只交付 Web Tina Mode、模式内 skills 和最少角色适配，不修改 DSH agent loop，不引入 Tina workflow engine。先解决四项明确问题：

1. **模式隔离**：决定 Tina policy 只随 preset 生效。现有项目共享 `AGENTS.md` 中的 Tina 路由会影响其他读取它的模式；DSH 专用安装路径需保留项目规则，同时避免把 mode policy 全局安装。DSH 的 instruction loader 默认读取 `AGENTS.md`、`CLAUDE.md` 及对应 local overlays；应保留项目规范，将 Tina 模式规则放入 preset。[instruction defaults:11](/Users/shenweimin/github.com/deepseek-ai/deepseek-harness/packages/context/agent-instructions/src/config.ts:11) 当前 installer 的 Codex 角色和共享 instructions 路径需要单独适配。[installer](/Users/shenweimin/github.com/tina-workflow/install.sh:1)
2. **角色语义**：映射 Tina TOML 的职责、模型、effort、sandbox；不能只迁移 prompt。固定 child id，并确认模型选择来自 Host 已安装路由。
3. **调用兼容**：核对 Tina wrapper 中 Codex 专属工具名、`$skill` 语法与 OpenSpec CLI 安装路径；vendored 文件保持不变。
4. **工作流门禁**：默认不自动开启 DSH plan mode、不因选中 Tina Mode 自动开启 YOLO、不因完成 verify 自动 archive。

最小验证应覆盖真实跨层行为：新 session 可选 Tina；standard 不含 Tina 常驻 policy；用户 slash 与模型 skill 加载都能拿到资源；角色使用预期 persona 和允许工具；reviewer 写入确实被阻止；同一个 reviewer 能接收修复后的复审；压缩/恢复后读回同一 run；原型写入不被误置于默认 plan mode；未授权 archive 不执行。仅比对 YAML 文本不足以验证这些行为。

本次执行了源码/文档/测试文件阅读及 Git 状态检查；未启动 DSH、未调用模型、未运行其测试。现有测试作为实现意图的交叉证据，不代表 Tina 集成已经验证。本文没有修改 schema、skills、agents、Target Instructions 或 installer，因此没有运行 Tina `./test.sh`。
