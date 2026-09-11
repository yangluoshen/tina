# Univer Office SDK：按需研究与路由

研究日期：2026-09-11。这是官方文档的研究快照，用于选择研究范围；它不替代目标项目所用版本的文档、完整示例和包类型。版本要求应在目标仓库核实并记录，不在 skill 中固定。

## 三部分的实际边界

官方文档使用 Web SDK、Server SDK、AI SDK 三个入口。Web 面向人类编辑，AI 面向 agent 操作；需要共享内容时，两者连接应用自己的 Server。AI SDK 复用 Web SDK 的 headless 能力，这三个入口不代表三套互不相关的引擎。[应用架构](https://docs.univer.ai/server/architecture.md)

| 需求 | 研究入口 | 应用仍需负责 |
| --- | --- | --- |
| 嵌入表格、文档、幻灯片等编辑器 | Web SDK：产品引擎、presets/plugins、Facade、模型、生命周期与框架集成 | 产品 UI、业务交互、集成与资源释放 |
| 多用户共同编辑、持久化、历史、评论、隔离草稿 | Server SDK：Collaboration 与所需扩展 | 用户、租户、ACL、业务 API、文件存储、部署 |
| LLM 读取、修改、检查 Univer 内容 | AI SDK：Node.js CLI、Inspection、API Reference、Execution、视觉检查 | 工具协议、目标映射、身份、提交策略、输出及任务边界 |

这些职责来自[应用架构](https://docs.univer.ai/server/architecture.md)。用户所说的 AI “client SDK”可理解为 agent 侧入口；当前官方准确定位是构建 Office CLI 的 TypeScript SDK，不能据此假定它只在浏览器运行、直接提供聊天产品，或固定采用某个 LLM/MCP 框架。[AI SDK](https://docs.univer.ai/ai.md)

仅本地单用户编辑可选 Web-only；AI SDK 也支持直接处理本地 Units 的 CLI-only 应用。Office 文件转换可单独使用 Node.js Exchange，不必连带引入协同或 AI。只有需求涉及共享修订、实时协同或相应扩展时，才研究并加入这些服务。[应用架构](https://docs.univer.ai/server/architecture.md)、[AI SDK](https://docs.univer.ai/ai.md)

## Web SDK：按产品和能力核实

- **Sheets**：官方列出单元格、行列、公式、格式、校验、筛选等能力，并支持浏览器与 Node.js。研究选定功能的安装、模型和 Facade，而非直接修改 snapshot 内部字段。[Sheets](https://docs.univer.ai/guides/sheets.md)
- **Docs**：官方列出排版、段落、页眉页脚、浮动图片与超链接等能力，支持浏览器与 Node.js。[Docs](https://docs.univer.ai/guides/docs.md)
- **Slides**：当前文档提供独立 Unit 类型、模型、编辑 UI、播放、Facade 及可选插件；包已位于 `@univerjs-pro`。不能沿用“Slides 尚未提供”的旧印象，也不能从文档存在推断所需 Office 特性已完全兼容。[Slides](https://docs.univer.ai/guides/slides.md)
- 当前索引还包括 Boards、Bases、PDFs。按需求重新查索引，逐项确认产品、扩展和 agent 工具覆盖；某一产品存在不表示所有 Server/AI 能力都覆盖它。[产品与功能索引](https://docs.univer.ai/guides/llms.txt)

这些页面没有提供可直接比较三种引擎生产成熟度的统一结论。涉及成熟度、导入导出保真度或特定格式兼容性时，记录目标版本、明确的功能证据与真实样本验证结果，不把产品介绍当成验收证据。

Web 路由：从[指南索引](https://docs.univer.ai/guides/llms.txt)找对应产品的 installation/quickstart、框架 integration、lifecycle、所需 feature/model 页面，再用[API 索引](https://docs.univer.ai/reference/llms.txt)核对 Facade、包名及类型。已有项目保留其 preset/plugin 组织方式，只增加需求所需模块。

## Server SDK：协同、扩展与应用权限

Collaboration SDK 是嵌入应用 Node.js 服务的组件，明确提供 OT、revision、snapshot、实时同步和持久化。其主调用链为：

```text
Web / AI collaboration client
→ Node Transport（HTTP / WebSocket）
→ Endpoint（协议、Session、Room、Presence、ACK、广播）
→ Service（Unit、OT、修订提交）
→ Database Adapter（原子存储、CAS、幂等）
```

SDK 不提供完整的用户、角色、目录、共享空间或业务流程；这些由应用拥有。[Collaboration overview](https://docs.univer.ai/server/collaboration/overview.md)

| 所需能力 | 实际边界与研究重点 |
| --- | --- |
| History | 从已确认 changeset 构造可重建历史索引；核心协同仍是内容权威源，历史不是每个 changeset 一条记录 |
| Thread Comment | 评论正文由独立服务/Adapter 管理，随内容移动的 anchor 属于核心内容；扩展总览明确描述 Sheets/Docs，其它产品需专项核实 |
| Worktree | 一个或多个 Unit 的隔离草稿；`ready` 冻结修订，合并逐 Unit 进行，多 Unit 合并不保证整体原子性 |
| Office Exchange | 文件转换与核心 snapshot API 的应用组合；文件 API、存储、大小限制和访问控制由应用实现 |

History、Comment、Worktree 各有独立 Service、Middleware、Events、Adapter 与释放责任；可共用物理数据库，不会自动继承核心权限规则。[扩展边界与示例入口](https://docs.univer.ai/server/collaboration/extensions.md)

身份接入应复用目标应用已有认证与 ACL：Transport 验证 cookie/session/token 后建立可信 `context.userID`；一次性 Session Ticket 把已认证身份带入 WebSocket。`memberID` 是连接身份，浏览器提交的 profile 也不能充当认证。[Identity and authorization](https://docs.univer.ai/server/collaboration/identity-and-authorization.md)

授权必须覆盖 HTTP `readUnitData`、实时 `joinUnit`、`submitChangeset` 与创建/删除/恢复生命周期。仅限制 JOIN 或把 UI 设为只读都不足以保护服务端；History、Comment、Worktree 还需各自的读写和生命周期策略。复用一个业务策略服务，避免给每个扩展另建 ACL 模型。[授权边界](https://docs.univer.ai/server/collaboration/identity-and-authorization.md)

Memory Adapter 仅适合临时数据；SQLite 面向开发、本地应用及小规模使用。自定义数据库接入必须满足 revision CAS、提交幂等、snapshot 可见性和生命周期原子性等完整契约，不能只实现 CRUD。事件是提交后的进程内尽力通知，不自动提供事务或可靠消息。[Database Adapters](https://docs.univer.ai/server/collaboration/database-adapters.md)

Server 路由：先读 [overview](https://docs.univer.ai/server/collaboration/overview.md)、[模块边界](https://docs.univer.ai/server/collaboration/modules.md) 和 [quick start](https://docs.univer.ai/server/collaboration/quick-start.md)，再按目标选择身份、存储或扩展。新增协同应验证两个独立浏览器上下文的同步；示例固定用户、always-allow 权限及 Memory 存储是教学配置，不能作为业务完成标准。[Quick start](https://docs.univer.ai/server/collaboration/quick-start.md)

## AI SDK：提供可组合工具入口

最小能力包括：加载 Unit 的 Runtime、结构化只读 Inspection、本地随 SDK 提供的 API Reference，以及执行 Facade 代码的 Execution。典型操作是先 inspect，API 不明时 find/show，Inspection 不覆盖时 execute read，修改时 execute write 并显式 commit。执行成功不等于提交成功；应用必须检查提交结果并释放 runtime。[Content operations](https://docs.univer.ai/ai/content-operations.md)

SDK 基础包暴露 TypeScript API，部分 command preset 提供 Commander 命令。应用拥有 root CLI、参数、目标定位、认证与输出；文档中的 `my-cli` 是示意名称，不能当成已经安装的命令。`content-execution` 只生成执行程序，不提供通用的现成 `execute` command preset。[AI SDK](https://docs.univer.ai/ai.md)、[Content operations](https://docs.univer.ai/ai/content-operations.md)

需要检查视觉效果时，使用确定的最新 UnitData → Render Runtime → Screenshot / Layout Lint。截图覆盖多种产品，但当前 Layout Lint 页面明确针对 Slide；不能宣称它统一检查所有文档排版。应用负责浏览器生命周期和图片输出。[Visual inspection](https://docs.univer.ai/ai/visual-inspection.md)

需要隔离 AI 修改供人类审阅时，Worktree 的 Service/Endpoint/Client/Adapter 属于 Collaboration SDK，AI 复用内容操作和视觉能力。应用把 `worktreeID + unitID` 映射到同一草稿目标：draft commit、Ready 和合入 trunk 是三个操作。这里的 Worktree 是 Univer 内容草稿，与 Git worktree 不同。[AI Worktree](https://docs.univer.ai/ai/worktree.md)

AI 路由：先 [AI overview](https://docs.univer.ai/ai.md) 与 [content operations](https://docs.univer.ai/ai/content-operations.md)，再选文件、视觉、Worktree 能力。只有重复加载成本已成为实际问题时再研究 [runtime pool / daemon](https://docs.univer.ai/ai/runtime-architecture.md)；它们不应成为默认脚手架。

## 版本、运行环境与许可

当前官方要求应用内 `@univerjs/*`、`@univerjs-pro/*`、`@univer-cli/*` 使用匹配的同一版本组合。检查目标 lockfile、package manifests、installed types/source 与当前文档是否对应，不能用网站默认文档直接解释旧版本。Node.js 下运行 Web 引擎、SQLite Collaboration、AI SDK 与 browser rendering 的前置条件分别核实；具体 runtime/engine 要求以选定包为准。[SDK requirements](https://docs.univer.ai/server/requirements.md)

需要许可的功能应核实所需 feature/release 的许可，并按项目现有 preset/plugin 模式提供 client license 内容；协同应用也在浏览器配置许可。License 控制功能可用性，应用 ACL 控制谁能访问内容。该页面不证明全部 SDK 免费或全部需要付费；不要凭包 scope 推断目标商业授权。[License](https://docs.univer.ai/server/license.md)

## 后续研究方法与交接

1. 先检查目标仓库的 manifest、lockfile、Univer 初始化、客户端/服务端入口、已有 research、认证与存储，明确需求涉及的产品和缺口。没有相关未知项时复用仍适用的证据。
2. 从 [llms.txt](https://docs.univer.ai/llms.txt) 和所需 [Web](https://docs.univer.ai/guides/llms.txt)、[Server](https://docs.univer.ai/server/llms.txt)、[AI](https://docs.univer.ai/ai/llms.txt) 子索引选择相关页面。完整阅读选中页面及其必要前置/架构链接；按需控制主题范围，不截断理解所需的调用链。
3. 实现应用前，读取最接近的官方示例 README 和完整代码，跟进配置、注册、共享模块、数据流与释放路径；还要读取相关 SDK root README、每个所用 package README。已有匹配版本的本地 checkout 可复用，否则将研究 clone 放目标仓库已有的临时/忽略目录。这是官方[开发前研究要求](https://docs.univer.ai/llms.txt)。本参考只完成路由研究，没有替具体应用完成此步骤。
4. 协同示例来自 [univer-collaboration-examples](https://github.com/dream-num/univer-collaboration-examples)，SDK 来自 [univer-collaboration-sdk](https://github.com/dream-num/univer-collaboration-sdk)；AI 示例来自 [univer-cli-examples](https://github.com/dream-num/univer-cli-examples)，SDK 来自 [univer-cli-sdk](https://github.com/dream-num/univer-cli-sdk)。Web 示例按所选产品文档定位。仓库或包访问失败时记录缺口，不能声称读过不可访问的代码。[官方仓库入口](https://docs.univer.ai/llms.txt)
5. 优先使用索引给出的 `.md` URL。尝试为普通页面补 `.md` 时，把后缀放在 query/fragment 前；验证状态码、正文标题和内容，防止把返回 200 的错误页当文档。失败后使用普通页面或页面标明的官方 source 链接。区分工具读取失败、页面不存在与实际能力缺失。
6. 把需求相关结论放进目标仓库已有研究目录的一份 dated Research Note：问题、本地版本/架构证据、已读官方页面与示例调用链、包/API 选择、验证结果、未知项、由此可推进的决定。明确区分官方事实、仓库事实和建议；实现前用 installed types/source 校验签名，禁止编造 API。
7. 将研究路径与决定显式交给下一步 Tina skill。普通 Univer Craft 给出一个当前可执行的下一步及具体目标，不把上面的 SDK 能力列表变成强制阶段。YOLO 模式使用同一研究门槛，再由 `$tina-yolo` 推进当前任务；缺失凭据、许可或不可访问源码属于应如实报告的实际限制。
