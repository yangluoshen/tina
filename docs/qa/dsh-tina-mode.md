# DSH Tina Mode 集成验收

日期：2026-09-17。结论：核心集成可用；关键兼容验证、真实 Web 和修复后 YOLO 续跑通过。初版 YOLO 为 FAIL，修复后在同一会话完成；完整计划仍有明确未覆盖场景。

## 环境与证据分级

DSH checkout：`/Users/shenweimin/github.com/deepseek-ai/deepseek-harness`，revision `0d1f50007f9bca3f52b06e1c3074fa14d5fb0720`。Node `v24.19.0`，pnpm `11.7.0`，macOS arm64。开始检查时 DSH tracked tree 干净。环境中存在 `DEEPSEEK_API_KEY`，本报告不记录其值；凭据存在不等于模型可调用。

测试 home 为 Tina 忽略目录 `tmp/dsh-qa-home`，使用显式 `DSH_HOME`，未安装 Tina 到日常 home。下列服务级测试使用真实 DSH registry、loop、持久化及 continuation 实现，模型边界使用 MockAdapter；不能据此认定模型遵循 Tina 阶段规则。

## 已完成的检查

在 DSH checkout 执行 `node node_modules/vitest/vitest.mjs run <spec paths>`。以下九个上游测试文件最终全部通过，共 334 个测试；初次缺少 native addon 的失败已通过构建 addon 后针对受影响文件重跑解决。

| 测试文件（相对 DSH checkout） | 观察到的行为 |
| --- | --- |
| `packages/core/tools/tests/scoped.spec.ts` | allowlist 同时约束工具 schema 和执行；未知工具被拒绝，限制按继承 scope 组合 |
| `packages/preset/persona/tests/persona.spec.ts` | persona scope 隔离、suffix、runtime context 和 complete 覆盖行为 |
| `packages/skill/skill/tests/skill.spec.ts` | registry scope 隔离、同名 skill 的最近 scope 优先、全局层保持原内容 |
| `packages/skill/skill-filesystem/tests/skill-filesystem.spec.ts` | filesystem skill 发现、来源、root 配置及资源读取 |
| `packages/subagent/subagent-in-process-driver/tests/preset-inheritance.spec.ts` | child 继承 parent preset 的工具及 prompt section；child filter 过滤继承工具 |
| `packages/subagent/subagent/tests/continuation.spec.ts` | continuable child 热消息、持久描述、同 id 冷恢复、错误 lineage 拒绝及取消行为 |
| `packages/subagent/subagent/tests/continuation-inheritance.spec.ts` | 冷恢复保留已落盘的权限、sandbox 和 approval 状态 |
| `packages/subagent/tool-subagent/tests/tool-subagent.spec.ts` | 角色工具的配置、深度、provider、调用边界 |
| `packages/subagent/tool-subagent-control/tests/tool-subagent-control.spec.ts` | send_message、parent/child 通信、冷恢复投递及非法调用者拒绝 |

原始输出：`tmp/dsh-phase0-direct-tests.log`（含初次缺 addon 的失败）、`tmp/dsh-phase0-persistence-tests.log`（四个相关文件，169 passed）、`tmp/dsh-phase0-role-tests.log`（67 passed）。这些临时日志不作为随版本分发的正式工件。

## 对设计的修正与边界

1. **Skill 来源**：最近 scope 的同名 skill 优先于全局 provider，与 rank 无关；rank 只解决同一层内部的重复。原研究关于全局 provider 覆盖 preset 同名技能的风险表述过宽。最终安装仍须检查 registry 的 `source` / `resourceBase`，识别同层重复或更近 scope 覆盖。[实现](../../../deepseek-ai/deepseek-harness/packages/skill/skill/src/index.ts)
2. **Reviewer 工具名**：`read`、`read_image`、`glob`、`grep`、`skill`、`send_message` 均是实际工具名称。`send_message` 用于向父级交还结论或请求代跑检查；此允许项不代表任意消息要求都获授权。[filesystem tools](../../../deepseek-ai/deepseek-harness/packages/fs/tool-fs/src/index.ts)、[search tools](../../../deepseek-ai/deepseek-harness/packages/fs/tool-fs-search/src/index.ts)、[消息工具](../../../deepseek-ai/deepseek-harness/packages/subagent/tool-subagent-control/src/index.ts)
3. **Allowlist 不是 OS sandbox**：child scope 后续直接注册的工具不受继承工具过滤影响。更关键的是 Host 的 tools mode 为 `ptc` 或 `both` 时，`run_code` 传输入口明确保留在 allowlist 之外，只有 SDK bindings 被过滤。必须在真实 child 的最终模型工具目录中断言不存在 `run_code`、shell、写入或再次委派入口；不能仅检查 YAML allowlist。[scope tests](../../../deepseek-ai/deepseek-harness/packages/core/tools/tests/scoped.spec.ts)、[PTC tests](../../../deepseek-ai/deepseek-harness/packages/core/tools/tests/ptc.spec.ts)
4. **冷恢复机制**：父级 `send_message` 指向原 child id；runtime 经 session query 读取持久 session，验证 durable direct parent，重建 descriptor 中的 persona、toolFilter、provider/model/effort，再投递到相同 child id 的新 Activation。无需重新调用 spawn provider。缺失 descriptor、错误 parent 或查询不可用均失败。[实现](../../../deepseek-ai/deepseek-harness/packages/subagent/subagent/src/continuation.ts)
5. **证据限度**：已有测试覆盖同一 Host 内 child Activation 消失后恢复和新 Context 重建；下文另外记录实际 Tina preset 的父 Web 会话重启、同 reviewer 复审及 suffix 组合验证。业务阶段、压缩恢复和 P0 修复故事不能由这些兼容性结果推定通过。

## Host 启动与环境修复

- `pnpm install --offline --ignore-scripts --frozen-lockfile` 成功；恢复缺失 workspace dependency 链接，未修改 dependency pins。
- `pnpm run build:native-system` 成功；生成 macOS arm64 addon，解决持久化文件锁导致的测试前置失败。
- `DSH_HOME=<Tina repo>/tmp/dsh-qa-home node --import tsx/esm apps/cli/src/bin.ts --profile web --help` 成功，确认受支持入口和 `--no-open --host 127.0.0.1 --port 0` 参数。
- 同入口实际 Web boot 首次失败：缺失部分 `lib/typert.host.js`，部分现有 typert codec 无 `create()`，以及 client artifact 不完整。随后通过支持的 `pnpm run build` 重建成功，记录 240 个 client artifact。构建曾因九个已删除 package 的忽略目录残留失败；确认每个目录无 tracked 文件、仅含 `lib/` 与 `node_modules/` 后，将其移入 `tmp/dsh-orphan-build-artifacts` 备份，再构建通过。DSH tracked tree 保持干净。

## 验收范围

阶段 0 的只读工具、skill 来源和持久 child 已取得真实 Host 证据。阶段 4 分别记录普通模式停止点、取消的有限证据和修复后 YOLO 续跑；复杂场景未覆盖项见文末。

## 真实 Web 与模型验收（已观察到）

受支持的 built 入口 `DSH_HOME=<isolated home> node apps/cli/lib/bin.js --profile web --no-open --host 127.0.0.1 --port 0` 已启动，浏览器可在同一 picker 选择 Standard、PTC、Minimal、Creator 和 Tina Mode。测试 Host 的额外 patch 只指定安装后的 preset root，并使用 DSH 自带 browse directory picker 的 Host/UI 配对，以便自动化操作；默认 macOS native picker 不适合 headless browser 操作。

- 项目：`/private/tmp/tina-dsh-qa.6KYR7k/project`；preset：`/private/tmp/tina-dsh-qa.6KYR7k/presets/tina`。由本次 installer 实际创建并通过 OpenSpec schema validation。
- Parent session：`session-2ae4872d-b21b-4e41-82d9-90dec7401e25`；reviewer child：`75abfec5-b844-449b-91db-c7c5a56f64ff`。UI 在未发第一条消息前从 standard 切换到 Tina，原 session header 保留 creation-time standard，随后真实 system prompt 与 child descriptor 显示 Tina；不能仅凭原始 header 判定实际模式。
- Persisted child request/header 的真实路由：`deepseek-official / deepseek-flash / high`；model-visible 工具正好六个：`glob, grep, read, read_image, send_message, skill`，没有 `run_code`、shell、mutation 或委派工具。
- Child 的真实 system/message 同时包含独立 reviewer persona 与 Tina 完整公共 suffix，包括 runtime-first、角色职责、阶段授权、archive 独立授权和复用 child id；这一结论来自日志，不依赖模型描述。
- Parent 与 child 的 `skill` 结果均从上述 preset 的 `skills/tina-dsh-runtime` 读取，伴随 `target-instructions.md` 可读。模型两轮读取 `openspec/config.yaml`，实际结果为 `schema: tina`。
- `tina_code_reviewer` 实际调用使用 `run_in_background: true`；持久 descriptor 为 `mode: continuable`、`provider: spawn` 并包含六项 allowlist。随后 `send_message` 将反馈交回同一个 child，child 在同一日志中完成 turn 2；未创建替代 reviewer。
- 首轮模型误将 reviewer 不含 `tina_*` 委派工具当作 suffix 未保留而报告 FAIL；第二轮澄清后报告 PASS。模型自述不作为 suffix 验收证据，以前述真实 system/message 为准。模型协调者还曾把尚待返回的 round 2 表述为已报告；本次没有据此宣称业务流程通过。
- 首轮实际耗时约 9 分钟，后续消息轮为 8–12 秒。真正停止并重启 Host 后的同 child 第三轮也已完成，详见冷恢复记录。

## 并行提供的仓库验证

主实施者报告 `./test.sh` 全部通过（日志 `tmp/dsh-test.log`），覆盖原 Codex smoke、DSH 幂等安装、config 内容/权限保留、vendor/OpenSpec 字节一致、冲突与 symlink、旧安装拒绝、实际注入校验失败回滚及 DSH_HOME 默认解析。提案交接修复后，主实施者重新执行整套 `./test.sh`，仍全部通过；验收 agent 未重复该检查。

独立 `dsh_code_review` agent 已返回 Approved，无 P0/P1；范围为完整实现 diff，包含安装事务、native presentation、tool filter 和 continuable 语义。同一独立审查者对最新两处交接/等待提示修复再次复审，结论仍为 Approved、无新增 P0/P1。该代码审查结论与真实会话 QA 分开记录，不替代用户故事验收。

## 冷恢复与强制拒绝（真实 Host）

停止整个 Web Host 进程，使用原隔离 home 重新启动，并在浏览器恢复原 parent 会话后，用户显式要求继续原 reviewer 第三轮。child 同 id 完成 turn 3，重新读到 `schema: tina`，返回 `QA-COLD-ROUND-3`。没有新 reviewer 被创建。

为独立检验隐藏工具不可执行，测试 profile 挂载临时 `tmp/dsh-reviewer-probe.mjs`，在该 child 恢复后的首个 pre-step 直接调用真实 `ctx.tools.execute`，依次尝试 `write`、`bash`、`run_code` 和 `tina_implementer`。四次均返回 `isError: true`、`code: UNKNOWN_TOOL`，目标文件 `qa-forbidden-write` 不存在。探针不改变 production preset 或 DSH tracked 源码。原始结构化证据：`tmp/dsh-reviewer-probe.jsonl`。

同一探针读取最终 assembly：六项工具集合无变化；`deployment:persona-prefix` 是 reviewer persona，`deployment:persona-suffix` 包含 Tina 公共规则；26 个最终 skill 均来自 `tina-filesystem` provider。此前两个 review 轮已完成，真正重启后第三轮通过，因此热复用与 Host 冷恢复分别取得实证。

原生工具 presentation 的七个既有测试通过；另外两个定向 PTC 测试确认 Host 默认 PTC transport 原本会绕过 scope allowlist。Tina composition 显式 native presentation 后，真实 child 的 `run_code` 强制执行已被拒绝。

## Standard 隔离

同一 Host、同一项目创建 standard 会话 `session-3679548e-ee52-49cf-ab1b-d53133921b1f`，以 Off effort 发出只回复 `STANDARD-OK` 的请求。真实 system/message 不含 `This session uses Tina Mode`，最终 request/header 无任何 `tina_*` 角色工具；Tina 会话仍保留独立 suffix 和 reviewer。原始完整记录在 `tmp/dsh-standard-isolation.jsonl`。

## YOLO 故事配置

会话 `session-8115a08e-97d8-462f-9e54-c86200273a7c`，路由 `deepseek-official / deepseek-flash / off`。已从 Web 选择 Tina Mode 并显式发送 `/tina-yolo`：实现标准库 Python 双整数加法 CLI、非法输入非零退出、最小黑盒测试、README，要求 implementation Change + 独立 QA Change、全局 proposal reviewer、独立实现/QA/code review、逐 Change 本地提交与 verify，禁止 push/deploy/archive。该项目已单独 git init 并建立安装基线，本地 Git identity 仅在 disposable 项目配置。

## 普通模式与取消（短会话）

普通会话 `session-8660cafe-05e1-459a-b058-6a90473e2206` 位于独立 `normal-project`，使用同 Host 的 Tina Mode，Off effort。用户明确仅规划讨论、不写文件、未授权 apply。模型加载 runtime/规划规则并执行只读检查，约 11 秒后列出行为和验收点，停在确认问题；没有委派 implementer、创建 goal 或文件写入。该证据覆盖显式未授权实施的停止点，不代表完整普通 proposal→确认→实施路径已验收。

随后在同一短会话单独请求有 8 轮上限的只读 goal，以测试取消。UI `Pause goal` 写入 `goal/change operation: pause`、revision 2、phase paused；用户追加“取消、不再继续、不恢复 goal”后，模型确认停止，未调用 resume、未写文件或创建 child。后续日志停在 turn 11 completed。此次 pause 时 `roundsStarted` 已到 8，无法排除轮数上限同时阻止续跑，因此只证实“已暂停 goal 未被模型重新开启”，不能单独证明运行中取消会立即中断任意工具。证据：`tmp/dsh-normal-and-cancel.jsonl`。

## 首次 YOLO：FAIL，修复后续跑

首次运行不能判为完整通过。全局 proposal reviewer `3c52ac2e-2252-4e76-bcb2-4677ae3bef56` 返回 `Needs changes` 后，协调者自行修改两份 Change 的 `design.md` 及 QA proposal/tasks，并提交 `4de4838`，此前没有向原 proposer 发送任何修订消息。这直接违反“修订回到原 proposer”的设计要求，记为本适配的 P0 验收失败。原始证据保存为 `tmp/dsh-yolo-before-proposal-fix.jsonl` 和 `tmp/dsh-paused-*.jsonl`。

同一个 reviewer 随后完成第二轮并继续 `Needs changes`（主要问题已解决，仍有编号交叉引用残留），证明 reviewer 复用本身有效，但不抵消 proposer 交接失败。协调者此前反复用 `bash sleep 90/150/180/200` 等待，造成数分钟额外延迟；Host 的子结果消息已入 inbox。原 adapter 未明确说明必须结束当前 assistant turn，这一等待语义也纳入最小修复。

根代理安排新的修复 agent 修改 Tina 自有 preset suffix 与 runtime：明确协调者不得直接编辑 proposer 的 proposal/specs/design/tasks，反馈必须回原 proposer，整组回同 reviewer；产品代码 P0 才另建 fresh implementer；等待子任务时结束当前轮，保持任务/goal 未完成，不用 sleep/轮询。未改 DSH 或 vendor/schema。

验收者在只执行 sleep、Git clean 的位置通过 Web 暂停 goal 并停止当前生成。持久日志显示 goal paused、turn aborted reason user；随后更新隔离安装的两份私有文件，重启原 Host，并显式请求继续同一 session。恢复后第 2 条真实 system/message 已包含全部新 suffix，模型重新加载 runtime。模型尝试 `update_goal` revision 2 / resume，被 Host 以 `GOAL_TOOL_RESUME_PAUSED` 拒绝：暂停的 goal 只能由用户恢复。后续业务由显式恢复消息和子结果消息推进，goal 仍 paused/disarmed，不能描述成 goal 自动接续成功。此为修复后续跑，保留首次 FAIL，不算从零无干预完成。

## 修复后实际阶段交接

修复后的 coordinator 将所有既有提案修改交回原 proposer 核对并接管，随后送同一全局 reviewer 第三轮；只有收到真实 `Approved` 后才进入实现。恢复后未再观察到 sleep 等待或 coordinator 直接修订 proposer 产物。此结果依赖一次明确披露原失败的人工恢复消息，不等同于新版本从零完全自主运行通过。

| 顺序 | 执行者 / 子会话 | 真实结果与提交 |
| --- | --- | --- |
| 1 | 原 implementation proposer `64ea94fc-1272-4e1c-baaf-e0751a88c887` | 核对、接管修订；`794b9e9` |
| 2 | 原 QA proposer `adaaf34f-63cb-4e33-8ac2-f068f78ff248` | 修正残留引用；`ff53c52` |
| 3 | 原 proposal reviewer `3c52ac2e-2252-4e76-bcb2-4677ae3bef56` | 第三轮 `Approved`；记录 `dd6b7bf` |
| 4 | 独立 implementer `8c01e38a-f672-4f3e-9840-e6d2aee2a174` | 完成 `add-integer-cli`；逐 Change 提交 `cba075a` |
| 5 | 独立 QA `9c45f392-c10b-4033-820b-238f0fedcc48` | `QA passed`，真实进程 32/32 断言；QA Change 提交 `6c44d0d` |
| 6 | 独立 code reviewer `f958ff23-07e3-4454-9efc-ac0d44be44ca` | `Approved`，无未解决 P0，3 项 deferred P2；记录 `d70a1aa` |
| 7 | Coordinator tina-verify | 两个 Change 均 `Ready to archive`，23/23 场景；最终记录提交 `7e1f9c9` |
| 8 | Web 用户 Resume goal → coordinator | UI 恢复为 revision 3，模型 complete 为 revision 4 / phase complete；全部 todo 完成 |

Code reviewer 保持六工具只读边界，要求父级代跑实际命令。它曾认为突变体结果 `passed=7 failed=11` 算术不一致；父级重新运行并逐项展示真实进程结果，同 reviewer 检查后明确撤回自己的误报，再返回 Approved。这覆盖“只读 reviewer 请求验证→父级代跑→回同 reviewer”的实际故事；不能把 reviewer 的最初判断直接作为产品缺陷。

验收者另行运行真实产物：`python3 test_add.py` 得到 18 passed / 0 failed；`add.py -7 2` 输出 `-5`，`add.py 0 0` 输出 `0`；`add.py bad 2` 返回 2 且 stdout 为空。以上是独立命令观察，与模型总结分开。

完成核对：项目工作树干净，两个 Change 仍在 `openspec/changes/`，未归档、未 push/deploy。测试者最后通过 Web 的 Resume goal 支持入口恢复，并要求只核对既有证据、完成 goal；模型正确 complete，未重新实施或修改产品。此时才取得 goal 完成证据，保留此前 paused/disarmed 期间业务续跑的事实。

## 尚未覆盖

- 新版本从零、无人介入的完整 YOLO；本次完整故事是保留初版 FAIL 的修复后续跑。
- 普通模式完整 proposal→用户明确授权→apply；本次只覆盖明确禁止实施时的停止点。
- 架构 hash 不一致引发的停止、重规划及重新审批。
- 上下文压缩后恢复；实际完成的 Host 进程冷重启不能代替该情形。
- 产品代码 P0 触发 fresh implementer、重新 QA/review 的全闭环。此次修复的是 Tina 编排规则，不能外推为产品 P0 故事通过。
- 任意长工具执行中的即时取消，以及缺失 provider、浏览器或凭据的完整降级故事。

原始 session 证据位于忽略目录 `tmp/dsh-qa-home/sessions`，可用 `zstd -qdc <session.v3.jsonl.zstd>` 读取全部连续 frame。复现工具边界需要本报告指定 DSH revision、构建完成的 Web Host、独立 home/preset root、可用模型凭据和 `tmp/dsh-reviewer-probe.mjs`；该一次性探针绑定测试 child id，不是产品插件。所有构建备份与原始证据保留，不修改日常 home。

收尾：测试 Web Host 已正常发送 SIGTERM 并确认退出；DSH tracked tree 与 disposable 项目工作树均干净。隔离 home、session 原始证据和构建备份保留。
