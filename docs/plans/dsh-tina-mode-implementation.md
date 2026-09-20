# DSH Tina Mode 实施计划

日期：2026-09-17。状态：首版实现完成，安装回归、关键兼容能力及修复后的最小真实 YOLO 闭环通过；下列未勾选的扩展验收仍未全部完成。

设计依据：[DSH Tina Mode 集成研究](../research/dsh-tina-mode.md)。本计划将该研究落成 Tina 仓库内的 preset、运行时适配和安装能力；研究记录的 DSH commit 是首次验证基线，运行前需核对实际 checkout。下文保留实施前确定的设计与门槛；实际完成范围以执行记录、勾选状态和验收报告为准。

## 执行记录

2026-09-17：已交付 `presets/dsh/tina`、`tina-dsh-runtime`、阶段 wrapper 适配、DSH installer 分支和管理文档。DSH 安装复用现有 Codex installer 的临时载荷；新增 `openspec/.tina-dsh.json` 记录运行时和共享 preset 落点。未安装到日常 DSH home，未提交或发布代码。

`./test.sh` 已通过，包括 Codex 回归、DSH 幂等、原样依赖资源、冲突与 symlink 拒绝、保留原配置和权限、实际注入验证失败后的回滚。`node --check`、`sh -n` 和 `git diff --check` 通过。独立代码审查结论为 Approved；真实 Host/模型证据、首轮失败及未覆盖的故事集中记录在[集成验收](../qa/dsh-tina-mode.md)，代码审查不替代该验收。

首轮真实 YOLO 在全局提案审查返回 Needs changes 后，协调者自行修改了提案，未交回原 proposer，因此该次完整故事判为失败。已在常驻 persona 和 DSH adapter 明确提案所有权、原 proposer 修订与同 reviewer 复审，并明确异步等待应结束当前轮次、保留任务未完成。修复后的 `./test.sh` 和独立代码复审再次通过；修复后原两位 proposer 接收反馈并完成修订，原全局 reviewer 第三轮 Approved 后才启动独立 implementer；等待改为结束当前轮次，由完成通知接续。该最小任务随后完成独立实现、逐 Change 提交、独立 QA、完整代码审查与 verify，Changes 保留未归档。具体 session、child、commit 和剩余验收范围见验收报告。

实施时确认两项补充：DSH skill registry 的同名条目按最近 scope 优先，不能将全局 provider 一概视为会覆盖 preset；PTC transport 不受普通 allowlist 限制，因此 Tina composition 显式使用原生 `agent-tool-presentation` 的 `mode: native`，并要求核对最终 child 工具目录。

## 目标与完成标准

用户在 DSH Web 新建会话时选择 **Tina Mode**，即可按 Tina 的阶段规则完成研究、规划、原型、提案、实现、独立 QA、独立代码审查和验证。用户也可以明确调用 `/tina-yolo`，授权当前任务自动执行至验证完成。归档始终需要单独请求。

交付必须同时满足：

- Tina 与 standard 会话能在同一 Host 共存，Tina 常驻规则和随 preset 分发的技能不主动注入 standard。
- 七个 Tina 角色均能执行各自职责；反馈可以回到同一个 proposer、architect、prototype agent 或 reviewer；P0 修复使用新的 implementer。
- OpenSpec schema、Proposal Plan、Prototype Note、Architecture Model 和现有 QA/review 记录继续承担原有职责，不另建流程数据库。
- 普通模式保留阶段交接和人工确认；YOLO 的模型决策标记、独立审查、逐 Change 提交和验证闭环完整保留。
- 安装能重复执行、拒绝覆盖用户修改，失败时不留下被当作可用版本的半成品；现有 Codex 安装通过回归检查。
- 真实 Web 会话完成下文的验收故事；配置加载成功或模型口头报告成功均不能替代验收证据。

首版交付范围是 DSH Web 和已验证 Host 提供的能力。CLI/headless preset 启动、新 workflow engine、自定义 DSH agent loop、通用 Codex TOML 转换器、自动部署和自动归档不在范围内。只有现有组合机制无法满足已列出的验收条件时，才提出有具体失败证据的 Host 扩展。

## 一、确定的设计选择

### 1. Preset 与常驻规则

使用 id `tina`，显示名 `Tina Mode`。从研究基线的 `standard/agent.cordis.yml` 完整复制并定点修改，保留其 realm、Host 依赖、工具和恢复机制。仓库维护的是 Tina 自有组合文件；不修改 DSH 内置 preset，也不假设存在 `extends: standard`。

persona 保持 `complete: false`、`includeRuntimeContext: true`。prefix 只声明协调者身份；suffix 放共同工作流规则、角色边界、恢复步骤和授权约束。共同规则明确区分主协调者与被分配的子 agent，避免子 agent 继承后再次启动完整流程。详细阶段步骤继续放在 skills 中。

首版在普通 DSH 会话模式执行 Tina 规划。若用户已开启 `/plan`，按 DSH 规则停留在只读规划并说明当前限制；不得静默退出或以 Tina 规则覆盖 DSH 的禁止写入约束。Tina 的计划确认与 DSH `exit_plan_mode` 审批不合并。

### 2. Skills 与规则来源

随 preset 分发 `skills/tina-*`、完整的上游 skill 资源目录及原样生成的 OpenSpec skills。安装阶段组装这些资源，不在源码仓库再维护一套完整副本。继续遵守 [ADR 0001](../adr/0001-separate-upstream-skills-from-private-policy.md)：兼容说明只进入 Tina 私有文件，vendor 和 `openspec-*` 保持原样。

首版将 preset 的 filesystem skill provider 配置为 `includeDefaultRoots: false`，通过 `baseUrl` 加载随包的 `skills/`，避免项目旧版 Tina skill 自动覆盖当前 bundle。项目 `AGENTS.md`、`CLAUDE.md` 和适用领域文档仍由原有指令读取机制处理。项目/用户额外 skill 的自动发现暂不启用；确有需要时显式加入经过核对的目录。

这个配置不能屏蔽 Host 全局注册的其他 skill provider。安装后的运行时检查必须验证 Tina、OpenSpec 及必需上游 skill 的最终来源；同名技能胜出来源不符合预期时，报告冲突并阻止该安装被判定为可用，不通过重命名或修改 vendor 掩盖问题。

新增一份随 preset 携带的私有 `tina-dsh-runtime` skill，集中说明工具映射、资源路径、goal 和恢复协议；suffix 要求主协调者与角色在执行前加载。现有 Tina wrapper 只在运行时相关位置改为中性描述或引用该协议，继续服务 Codex。禁止靠批量替换 `$`、模型名或路径来生成另一套 skill 正文。

DSH 用户入口使用 `/tina-*`；模型调用 `skill` 加载确切名称。wrapper 内的 `$skill-name` 表示技能引用，由适配协议映射为加载操作。依赖资源通过实际加载目录定位，清理 Tina 自有文件中对 `.agents/skills/...` 的硬编码假设。

### 3. 角色、模型与权限

七个角色通过七个唯一名称的 `dsh-tool-subagent` 工具装配，默认使用 `provider: spawn`、`backgroundMode: continuable`。职责以现有 [agents](../../agents) 文件为语义依据，在 Tina 私有 YAML 中明确表达；不声称 DSH 会读取这些 TOML。

| 工具名 | 任务范围 | 结果与权限要求 |
| --- | --- | --- |
| `tina_architect` | 一份有界 Architecture Model 的绘制、校验和修改 | 返回 JSON、hash、投影视图；不实现产品代码 |
| `tina_prototype` | 已规划问题的可运行一次性原型 | 返回运行方式和验证结果；由主协调者记录接受结论 |
| `tina_proposer` | 一个 implementation 或 QA Change 的提案产物 | 不重新拆分整个请求，不实现；超出范围返回主协调者 |
| `tina_proposal_reviewer` | 全部提案的一次全局审查 | 仅允许核实过的只读工具；返回统一 verdict |
| `tina_implementer` | 一个实现 Change 或一次明确的 P0 修复 | 在既有权限下修改、验证；主协调者检查归属并提交 |
| `tina_qa` | 原始用户故事和跨 Change 验收 | 可准备环境、执行测试、写 QA 证据；不修产品代码 |
| `tina_code_reviewer` | 原始请求的完整实现及修复 diff | 仅允许核实过的只读工具；返回发现，由主协调者持久化 |

两个 reviewer 使用工具 allowlist，排除 shell、PTC、写入、通用 MCP 执行和再次委派等可绕过只读意图的入口。若确需运行命令，reviewer 向父级返回明确命令与验证目的；父级在授权范围内执行并把原始输出及退出状态交回同一 reviewer，由它裁定。QA 不套用 reviewer 的只读限制。

第一阶段实测后确定 allowlist 的精确工具名称，以及受限 child 能否使用既有消息机制；不得猜测名称后交付。角色工具的可见性和深度上限要阻止角色重新启动 Tina 编排，同时保留返回结果所需的能力。

模型策略使用 DSH Host 已配置的路由。首版继承父路由作为默认，允许通过角色行的 `agentOptions` 配置实际可用的 provider/model/effort；不自动把 Codex 模型标识转换为 DSH provider。DSH 适配规则明确优先于 Target Instructions 中仅面向 Codex 的模型表，并在 run record 记录实际选择。显式配置不可用时报告错误，不静默换模型。

### 4. 状态、持续执行与恢复

继续以 `docs/proposal-plan/<date>-<scenarios>.md` 为请求级记录。在现有 Execution 信息中补充 Host/session 标识、角色与 child id 的映射、当前阶段、最近 verdict、待处理反馈；保留原始授权范围、Change 依赖、baseline/commit、架构 hash 和证据路径。不得以 child 的退出状态代替业务 verdict。

正常后续反馈通过 `send_message` 返回同一个 child。冷恢复时先核对持久 child 是否可继续，再发送反馈。若无法找回必须复用的角色，记录恢复阻塞及原 id，不静默创建替代 reviewer 并宣称满足“同一 reviewer”要求。

Goal 只承担续轮。DSH 更新 goal 前先读取其 id/revision，使用本运行时的 action 和轮数参数；只有主协调者可以完成整轮目标。恢复后 goal 未重新启用时，遵守 DSH 对用户继续意图的要求。用户取消后不得通过 hook 或子 agent 重新启动任务。

上下文压缩或恢复后重读计划、相关产物、当前阶段 skill、Git 状态和有效证据，再从最早未完成或已失效阶段继续。普通确认与 `model-decided (tina-yolo)` 保持可区分；复用仍有效的测试结果。

## 二、源码与安装布局

拟新增或调整以下文件；实施时允许因复用现有函数缩减文件数量，但职责不扩散。

| 路径 | 交付内容 |
| --- | --- |
| `presets/dsh/tina/preset.yml` | 显示名称和用途 |
| `presets/dsh/tina/agent.cordis.yml` | 完整组合、persona、技能来源和七个角色工具 |
| `skills/tina-dsh-runtime/SKILL.md` | DSH 运行时适配协议，仅分发给 DSH |
| `skills/tina-*/SKILL.md` | 必要的工具、路径和模型选择兼容调整，保留工作流语义 |
| `install.sh` | 新增 DSH 分支，复用现有复制、冲突检查和 schema 配置逻辑 |
| `test.sh` | Codex 回归和无需模型的 DSH 安装检查 |
| `docs/dsh-tina-mode.md`、`INSTALL.md`、`README.md` | 安装、Host 前提、模式选择、更新和限制说明 |
| `docs/qa/dsh-tina-mode.md` | 集成验收记录，附运行版本、会话、命令和证据 |

拟定安装接口为 `./install.sh --runtime dsh --preset-root <root> <target>`；原有 `./install.sh <target>` 保持 Codex 行为。`<root>` 是实际 Host 发现的用户可写 preset 根目录，默认按 DSH home 约定解析；显式配置了其他 roots 时允许传入正确路径，并在使用说明中要求核对发现结果。

DSH 安装分成两个落点：

```text
<preset-root>/tina/
  preset.yml
  agent.cordis.yml
  skills/                 # 安装时组装，包含完整引用资源和许可证

<target>/openspec/
  config.yaml             # 仅按现有规则设置 schema
  schemas/tina/
```

DSH 分支不向目标项目写入 Tina 的共享 AGENTS 托管块或 Codex agent TOML。OpenSpec 的技能生成在临时目录完成，可复用现有 Codex generator 作为生成来源；只复制经过路径兼容核对的生成 skills 和必要伴随文件到 preset，不把临时 AGENTS、Codex agents 或临时目录路径带进目标。

所有目标路径先做冲突和 symlink 检查，再写入；相同内容重复安装成功，不同内容拒绝覆盖。preset 和项目 schema 是两个写入位置，失败需恢复本次修改并保留先前内容。记录两处实际落点，便于排查。

已有 Codex Tina 项目可能含共享路由和旧技能。首版不自动删除这些内容；发现共享 Tina 托管块时，报告模式隔离尚不成立，要求先完成明确的迁移安排。验收中的隔离结论只针对已清除该冲突的项目，不把既有项目指令误报为 preset 泄漏。

首版升级沿用冲突拒绝规则，通过审阅差异完成受控替换，不增加另一套自动合并系统。现有 init/sync/remove skills 必须明确区分 DSH 与 Codex：尚未支持的 DSH 同步、移除和 incognito 操作应在写入前停止并说明范围。移除项目配置不能顺带删除其他项目仍在使用的用户级 preset；现有 OpenSpec Changes、specs 和证据不属于可清理安装载荷。

现有依赖继续使用 `dependencies.env` 中的 pins；不为此次适配升级上游。DSH 实测 revision 记录在验收文档，首版不引入运行时下载 DSH 的依赖。以后若分发依赖固定 DSH 来源下载，再将 pin 放入 `dependencies.env` 并扩展唯一的依赖更新入口，不能在 preset/skill 中散落版本常量。

## 三、实施顺序与交付门槛

各阶段按一个意图拆分，任务保持粗粒度；如果实施中超出 Tina Change size gate，再拆分该阶段。正式创建 OpenSpec Changes 时，最后一个阶段作为独立 QA Change，以原始用户故事组织验收，使用 `skip_specs: true` 引用产品规格。

| 阶段 | 建议 Change 名 | 依赖 | 主要交付 |
| --- | --- | --- | --- |
| 0 | 有界兼容验证，不创建生产功能 Change | 无 | 三项关键能力的真实结果 |
| 1 | `dsh-tina-preset` | 0 | 可加载的 Tina composition 和角色 |
| 2 | `dsh-tina-workflow-adapter` | 1 | 阶段调用、资源路径与恢复协议 |
| 3 | `dsh-tina-installation` | 2 | 两处落点的安全安装与使用说明 |
| 4 | `dsh-tina-acceptance`，QA Change | 1–3 | 完整故事的独立验收证据 |

### 阶段 0：验证角色权限、来源和恢复

- [x] 在临时 DSH home 和临时项目中，以受支持的 Web 启动路径加载 standard 的本地副本；记录 DSH revision、Host 配置、模型路由和启动方式。
- [x] 验证 persona suffix 在 role prefix 覆盖后保留；两个独立 session 的规则、角色和目录互不串用。
- [x] 启动 continuable child，完成一轮任务后发送修改意见；再冷恢复父会话，核对同一 child id 的继续能力。分开记录“热会话复用”和“冷恢复复用”的结果。
- [x] 用最终 registry 验证 skill 来源和 reviewer allowlist；主动尝试直接写入及通过剩余工具间接写入，保留拒绝证据。

退出条件：三项风险（角色只读、技能来源、持久 child）均有真实通过证据。缺少 Host/provider/模型条件则记录阻塞；任一机制不满足要求，先据此修订具体适配方案，不把未验证假设带进生产配置。临时原型不自动安装到用户正在使用的 DSH home。

### 阶段 1：交付 preset 和角色组合

- [x] 添加 preset metadata 和完整 composition，保留 standard 的必要分组及工具指导；记录复制来源与有意修改项。
- [x] 完成主协调者 prefix 与公共 suffix，明确普通/YOLO 路由、授权范围、角色继承和 archive 边界。
- [x] 添加七个角色工具和已验证的过滤配置；明确模型默认及可覆盖字段，消除角色再次启动整条流程的入口。
- [ ] 在实际 Host 加载组合，验证工具目录、persona、两种会话隔离、缺失 provider 或无效工具名的失败表现。

退出条件：新会话可以选择 Tina Mode，七个角色有正确职责及权限；standard 未获得 Tina 常驻规则。尚未完成安装和完整工作流验收时，只标记本阶段完成。

### 阶段 2：适配阶段技能与恢复

- [x] 编写 `tina-dsh-runtime`，给出 skill、spawn、消息、结果收集、goal 和实际资源路径的映射，明确 DSH plan mode 限制。
- [x] 逐个核对全部 Tina wrapper、七个角色职责及它们引用的资源；修正 Tina 自有硬编码，核验生成 OpenSpec skills 的调用方式，保持上游字节不变。
- [ ] 接通普通提案流程：计划和原型确认、条件架构及 hash 检查、每 Change proposer、全部提案完成后的唯一全局 reviewer、同角色修改回路。
- [x] 接通 apply、独立 QA、独立 code review、verify 与 YOLO；补充 session/child 映射和恢复记录。核验 QA Change 不被 apply 当作实现任务，子阶段不能提前完成整轮 goal。
- [ ] 用一个小任务验证阶段边界、P0 新修复 agent、同 reviewer 复审、P1/P2 延后，以及压缩后的阶段恢复。

退出条件：工作流不依赖 Codex 专属工具或 `.codex/agents` 发现；普通和 YOLO 两条路径都保留原有语义。现有 Codex wrappers 的行为不因 DSH 分支改变。

### 阶段 3：交付安装与维护入口

- [x] 扩展 installer 参数和运行时分支，复用已有载荷列表、冲突检查和 schema 处理；只有确有重复时才提取小的共享函数。
- [x] 在临时目录生成并组装完整 skills/资源/许可证，验证资源可搬移；预检 preset 与项目两处路径后再安装，失败恢复本次改动。
- [x] 验证空项目、已有项目、重复安装、不同 DSH home、自定义 preset root、冲突文件、symlink、部分失败和旧 Codex Tina 安装的诊断。
- [x] 更新安装文档及管理 skills 的运行时识别，说明新会话生效、受控升级、共享 preset 的移除边界及未支持的操作。
- [x] 运行 `./test.sh`，同时确认原有 Codex 安装和生成文件仍符合仓库约定。

退出条件：两处落点可复现，冲突前不覆盖、失败不损坏既有文件；安装文档中的步骤在干净环境执行通过。管理入口不能把 DSH 安装误按 Codex 载荷处理。

### 阶段 4：独立验收、代码审查与发布准备

- [ ] 建立独立 QA Change，覆盖下面的用户故事；验收者从原始目标、计划及实现结果执行，不复刻实现任务列表。
- [x] 记录真实 Web 操作、session/child id、产物路径、命令输出、Git diff 和 verdict，写入 `docs/qa/dsh-tina-mode.md`。
- [x] 独立代码审查检查完整 diff，重点检查重复 policy、安装冲突/回滚、角色权限和跨 session 状态；审查与 QA 各自回报结果。
- [x] 按 Tina 规则由新的 implementer 修复 P0，原验收者或 reviewer 验证相关修复；仅重测受影响故事，保留其他有效证据。
- [ ] 完成 Changes 验证，记录支持的 DSH revision、Host 前提和剩余 P1/P2。完成状态为可交付；push、发布和 archive 仍由各自明确请求触发。

## 四、验收故事与证据

| 用户故事 | 必须观察到的结果 | 最小证据 |
| --- | --- | --- |
| 安装后选择 Tina Mode，同时继续使用 standard | Tina 可选；standard 无 Tina 常驻 suffix，原项目指令仍有效 | 两个 session 的 prompt/catalog 投影与实际来源 |
| 用户先规划，再决定是否实现 | 能写计划、原型和提案；未授权时不进入 apply；默认不生成 HTML | 产物、确认记录、实施前 Git diff |
| 多个 Change 需要全局提案审查 | 所有提案完成后只启动一个全局 reviewer；修改回到原 proposer，再由同 reviewer 复审 | Change 列表、child id、消息及 verdict 顺序 |
| reviewer 发现问题但不修改项目 | 直接和间接写入被拒绝；父级代跑必要检查后，仍由 reviewer 判定 | 拒绝结果、父级命令输出、reviewer 复审结论 |
| 用户授权完整 YOLO 任务 | 包含独立 QA Change；实现逐 Change 提交；QA/review 独立；P0 修复闭环；验证通过后停止 | run record、提交列表、故事证据、最终 verdict |
| 请求含需要架构或原型验证的问题 | 独立角色交付并复用；记录接受来源；架构 hash 改变时回到规划 | Architecture Model、Prototype Note、hash 与返回路径 |
| 会话被压缩或重启后继续 | 重读相同 run，复用可恢复的角色和有效证据；goal 不绕过恢复授权 | 压缩/恢复前后 session 与 child id、阶段和任务状态 |
| 不可用模型、浏览器或服务导致无法完成 | 报告具体阻塞；不伪造通过、不擅自替换已指定模型或 reviewer | 错误、未完成任务、阻塞记录 |
| 重复安装或安装中遇到冲突 | 相同载荷幂等；用户修改保留；失败后无部分可用安装 | 前后文件 hash、目标 Git 状态、失败输出 |
| 用户未授权归档或取消任务 | verify 后不 archive；取消后不自行续跑；选中模式不等于启用 YOLO | 会话行为、goal 状态、Changes 保留情况 |

权限拒绝、路径冲突和恢复字段适合无模型的可重复检查；模型是否遵循阶段规则必须由真实会话验收。未授权 archive 的场景验证是工作流行为证据，不宣称仅靠提示词和 shell 字符串过滤已经建立强制安全隔离。

## 五、执行与验证约束

本计划文档不自动创建上述 Changes，也不授权安装到日常 DSH home 或修改 DSH 源码。后续实施优先在 Tina 仓库和临时测试环境完成，只有阶段 0 证明存在具体 Host 缺口时才另列 DSH 改动及其验证范围。

修改 schema、skills、agents、Target Instructions、installer 或依赖后，按仓库规则运行 `./test.sh`；只修改此计划无需运行安装测试。DSH 集成检查使用其受支持的启动方式和对应测试工具，不发明 headless preset 参数。运行证据必须区分源码检查、无模型检查和真实模型验收。

全部相关检查通过后进入交付，不为消除与本目标无关的 P1/P2 反复扩大测试。任何必需能力尚未验证、关键故事失败或 P0 未关闭，都保留未完成状态。
