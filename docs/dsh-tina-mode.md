# DSH Tina Mode

Tina Mode 在 DSH Web 中提供独立 preset，复用 Tina 的 OpenSpec 工作流、技能和七个角色。常驻规则只属于选择该 preset 的会话，项目领域规则仍按 DSH 的指令发现机制读取。

实际验证范围、DSH revision 和未完成的验收见 [验收记录](qa/dsh-tina-mode.md)。安装器成功只说明文件和 OpenSpec schema 安装通过，不能代替 Host 中的角色、技能来源和真实模型验收。

## 安装

需要 Git、Node.js 18+、npm、与 `dependencies.env` 匹配的 OpenSpec CLI，以及能正常启动的 DSH Web。DSH 自身的 Node.js/构建要求以所用 DSH 版本为准。Host 必须提供 standard preset 所需服务及 in-process `spawn` provider、持续协作和可用模型路由；Tina installer 不安装 DSH 或配置凭证。

从 Tina checkout 执行：

```sh
./install.sh --runtime dsh /absolute/path/to/project
```

默认 preset 路径是 `${DSH_HOME:-$HOME/.dsh}/.agent-presets/tina`。若 Host 的发现 roots 使用其他位置，传入实际的用户可写根目录：

```sh
./install.sh --runtime dsh --preset-root /absolute/path/to/presets /absolute/path/to/project
```

这两个参数都是文件系统路径；installer 不会自动添加 Host 的发现 root。源码、preset、目标项目不得相互包含。路径中的自定义 symlink 会被拒绝，使用其真实路径。现有 `./install.sh <target>` 继续安装 Codex 版本。

没有全局 OpenSpec 时，遵循 [INSTALL.md](../INSTALL.md) 的临时工具环境，用其中的 pinned `npm exec` 包裹上述命令；不要用 `latest`，也不需要全局安装。

安装先在临时目录运行现有 Codex installer，取得原样的 OpenSpec 和上游技能。最终只发布：

- `<preset-root>/tina/`：composition、metadata、全部 skill 资源及许可证。
- `<project>/openspec/schemas/tina/`：原有 Tina schema。
- `<project>/openspec/config.yaml` 或已有的 `config.yml`：设置默认 schema，保留其他内容。
- `<project>/openspec/.tina-dsh.json`：运行时及 preset 落点标记，供管理入口识别。

不会在目标项目新增共享 Tina AGENTS 块、`.agents/skills` 或 `.codex/agents`。已有同名内容只有逐字节相同时可重复安装；不同内容会报出冲突。写入或最终 schema 验证失败时，恢复本次修改的配置并清理本次新增的载荷。目标中已有的 OpenSpec Changes、specs、领域文档和代码均保留。

如果项目已经安装 Codex Tina，先处理共享 AGENTS 中的 Tina 托管块。installer 会拒绝直接混装，避免在 standard 会话中继续激活 Tina 路由；它不自动删除已有安装。已有项目/用户额外技能也不会默认进入 Tina preset，可在审阅后显式配置额外技能目录。

## 在 Web 中验证与使用

按 DSH 支持的 Web profile 启动 Host，选择目标项目，在**新会话**选择 `Tina Mode`。已有非空会话不能直接切换 preset。修改组合文件后使用新会话；修改在初始化时读取的资源时同步更新组合文件时间或重启 Host。`--profile` 选择 Host profile，不是 Tina preset，不能使用虚构的 `dsh --profile tina` 或 headless preset 参数。

首次使用前检查：

1. preset 没有加载错误，七个 `tina_*` 角色工具及 `subagent`、`send_message` 可用。
2. `tina-dsh-runtime` 及其 `target-instructions.md`、Tina/upstream/OpenSpec skills 来自同一 preset 的 `skills/`；必需资源不存在或来源不符时停止。
3. reviewer 的工具目录只有 `read`、`read_image`、`glob`、`grep`、`skill`、`send_message`，没有 `run_code`。preset 用 `agent-tool-presentation` 显式选用 native，并把该选择继承给 child。
4. standard 会话不含 Tina suffix 或该 preset 的私有 skills。共享项目/Host 全局指令独立于 preset，需要另外核对。

普通流程示例：

```text
/tina-research <问题>
/tina-propose-plan <目标>
/tina-prototype docs/proposal-plan/<date>-<scope>.md
/goal Execute /tina-propose-run docs/proposal-plan/<date>-<scope>.md. Follow its success criteria and stopping condition.
```

全局提案审查通过后，用户授权实现，再分别执行 `/tina-apply`、`/tina-qa`、`/tina-code-review`、`/tina-verify`。QA 和代码审查互相独立。需要整个任务自主执行时明确请求 `/tina-yolo <task>`；它不授权 push、部署或 archive。

Tina 规划需要写产物，使用普通 DSH 执行模式。若已开启 DSH `/plan`，agent 必须保留其只读限制；用户先按 DSH 的流程退出 plan mode，再继续产物写入。

## 角色与恢复

角色继承父模型路由。需要角色专用模型时，在对应 `dsh-tool-subagent` 行配置 Host 实际支持的 `agentOptions.provider`、`model`、`reasoningEffort`；该配置属于用户修改，后续安装会保留并报告冲突。不要把 Codex 的模型表当作 DSH provider 配置。

Tina 角色使用 `run_in_background: true`，返回的 child id 记录在 Proposal Plan 中。反馈使用同一 id 的 `send_message`，运行时完成通知携带结果；消息送达不等于审批通过。冷恢复后先核对 child lineage 和状态，再续接；不可恢复的 reviewer 要报告阻塞，不能静默替换。

reviewer 的工具 allowlist 限制它能直接执行的操作，不等于单独的 OS 只读沙箱。父 agent 根据授权代跑必要命令，返回原始证据，由 reviewer 独立裁定。Host 若增加 child-local 执行工具，必须重新核验最终目录和权限；不能只检查 YAML 中的 allowlist。

压缩或恢复时重新加载运行时适配、计划、当前阶段 skill、产物和 Git 状态；保留有效证据。DSH goal 的 id/revision/action 与 Codex 不同，恢复后是否重新启用也受 DSH 用户授权规则约束。用户在 Web 暂停的 goal 需要通过 Web 的 Resume goal 恢复；模型调用 `update_goal` 的 resume 会被 `GOAL_TOOL_RESUME_PAUSED` 拒绝。业务结果完成与 goal 状态分开核对。

## 更新与移除

首版不提供 DSH 自动同步、incognito 或移除。Codex 的 init/sync/remove skills 遇到 DSH 标记必须停止其 Codex 操作，不能混用载荷清单。

更新时先在临时位置安装新版本、审阅与已安装版本的差异，再按明确授权备份和替换选定路径。用户修改的 persona、模型或技能不自动覆盖。多个项目可以引用同一个 preset；移除一个项目的 schema/标记前检查其他使用方，不能顺带删除共享 preset，也不删除已有 Changes、specs 或验收记录。
