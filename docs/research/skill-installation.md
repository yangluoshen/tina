# 在目标仓库通过一句话安装工作流

研究日期：2026-09-11。Vercel Skills 源码快照为 [`80feb48868972d518436f26711509bc78595b5cb`](https://github.com/vercel-labs/skills/tree/80feb48868972d518436f26711509bc78595b5cb)。本文区分已核实的工具行为与针对本项目的设计建议；没有执行远程工作流安装。

## 结论与建议

建议提供一个面向 agent 的根目录 `INSTALL.md`。用户在目标仓库启动 Codex 后，要求它读取该文件的 URL 并安装到当前仓库，agent 获取完整源码、读取现有初始化 skill，再调用现有 installer。这样保留一套冲突检查、完整工作流资源和 incognito 行为，也不要求用户先进入工作流源仓库。

“现代安装方式”没有唯一入口：Vercel 提供 `npx skills add`，Codex 提供 `$skill-installer` 并支持项目目录技能发现；OpenAI 当前文档还建议用 plugins 分发可复用技能集合。因此应按实际安装载荷选择方式。[Vercel CLI](https://github.com/vercel-labs/skills/blob/80feb48868972d518436f26711509bc78595b5cb/README.md) · [OpenAI 官方 Build skills](https://learn.chatgpt.com/docs/build-skills)

## 已核实：技能分发工具安装什么

Agent Skills 规范定义的是一个包含 `SKILL.md` 的目录；目录内可以附带脚本、引用文档和资源。规范没有定义自动执行仓库根 `install.sh` 的安装生命周期。[Agent Skills 规范](https://agentskills.io/specification)

### Vercel Skills CLI

命令中的包名是复数 `skills`。以下是其官方支持的形式；最后一条在当前项目安装选定技能到 Codex 使用的路径，`--yes` 关闭 CLI 的确认提示：

```sh
npx skills add owner/repo --list
npx skills add https://github.com/owner/repo/tree/main/path/to/skill
npx skills add owner/repo --skill skill-name --agent codex --yes
```

仓库简写、完整 Git URL 和本地目录均可作为来源；默认项目级，`--global` 改为用户级，`--copy` 选择复制。`--skill` 按技能名筛选，不是执行该技能。[官方 README](https://github.com/vercel-labs/skills/blob/80feb48868972d518436f26711509bc78595b5cb/README.md)

Codex 的项目目标目录配置为 `.agents/skills/`；该 CLI 的 Codex 全局配置使用 `$CODEX_HOME/skills`，未设置时为 `~/.codex/skills`。这与 OpenAI 文档列出的用户级本地发现目录 `~/.agents/skills` 应分别描述，不能将不同工具的目录约定混写。[CLI agents.ts](https://github.com/vercel-labs/skills/blob/80feb48868972d518436f26711509bc78595b5cb/src/agents.ts) · [OpenAI 本地技能发现](https://learn.chatgpt.com/docs/build-skills#where-codex-loads-local-skills)

源码安装路径是选择技能后调用 `installSkillForAgent`，从所选技能目录递归复制文件，再按 agent 配置建立链接或复制。它会带上该目录内的 `scripts/`、`references/`、`assets/` 等文件；源码中没有执行来源仓库 `install.sh` 的步骤。仓库根本身若是技能目录，文件也只是复制到技能安装目录，并不会被部署到目标项目的对应根目录。[add.ts](https://github.com/vercel-labs/skills/blob/80feb48868972d518436f26711509bc78595b5cb/src/add.ts) · [installer.ts](https://github.com/vercel-labs/skills/blob/80feb48868972d518436f26711509bc78595b5cb/src/installer.ts)

项目安装还会记录 `skills-lock.json`。它追踪技能来源、路径和内容哈希，不能代替工作流对 schema、subagent 配置、指令托管块的版本管理；也不能据此承诺 Git 状态不变。[项目 lock 实现](https://github.com/vercel-labs/skills/blob/80feb48868972d518436f26711509bc78595b5cb/src/local-lock.ts)

### Codex 原生安装与发现

OpenAI 官方文档允许用户直接要求 `$skill-installer` 从其他仓库下载技能。Codex 从当前目录到仓库根逐层发现 `.agents/skills`，并支持链接目录；新技能通常自动发现，未出现时再重启。[OpenAI 官方 Build skills](https://learn.chatgpt.com/docs/build-skills)

OpenAI 的安装器支持 GitHub repo/path、URL、指定 ref 与目标目录。其源码检查所选目录包含 `SKILL.md` 后调用 `shutil.copytree`，目标已存在则报错；它同样不会执行源仓库的工作流 installer。默认目的地是 `$CODEX_HOME/skills`。[OpenAI skill-installer 源码](https://github.com/openai/skills/blob/main/skills/.system/skill-installer/scripts/install-skill-from-github.py)

## 已核实：一句话读取安装指南已有实践

Superpowers 的维护者在 OpenCode 安装说明中，直接要求用户让 agent 获取并遵循 `.opencode/INSTALL.md` 的远程 URL。该项目当前对 Codex 推荐插件入口，不能把旧版 Codex 指南当作当前官方推荐。这说明“用户给 URL，agent 读取安装协议”是现有分发方式之一；将其用于本项目是下面的设计建议。[Superpowers 官方 README 的 OpenCode 与 Codex 安装部分](https://github.com/obra/superpowers/blob/main/README.md)

## 本项目的安装契约

Tina Init 依赖 bundle 根的 `install.sh`、`dependencies.env`、`templates/AGENTS.md`，并要求 installer 处理目标冲突。其载荷包含 skills、OpenSpec schema、Codex agents 和 Target Instructions，因此复制单个 init skill 会丢失它引用的源仓库上下文。[Tina Init](../../.agents/skills/tina-init/SKILL.md) · [安装器](../../install.sh)

建议在两份工作流源码中分别维护自己的 `INSTALL.md`，保持各自拥有自己的安装协议。Tina 的指南只描述 Tina；依赖 Tina 的扩展由扩展指南初始化其固定依赖、选择组合 installer。指南只负责获取源码和进入现有初始化流程，不重复实现复制、合并或冲突处理。

用户入口示例：

```text
请读取 https://raw.githubusercontent.com/yangluoshen/tina/main/INSTALL.md，按说明将 Tina 安装到当前仓库。
```

```text
请读取 <扩展仓库的 INSTALL.md URL>，按说明以 incognito 模式安装到 /absolute/path/to/project。
```

以上是拟议接口。发布并确认 URL 可访问后才能作为可运行示例；尚未配置远端的扩展仓库不能宣称已有公开安装地址。实现期可以用本地 `INSTALL.md` 绝对路径验证同一流程。

指南应明确以下步骤：

1. 用户明确指定目录时解析为绝对路径；用户说“当前仓库”时，在更改工作目录前记录当前 Git 仓库根。先记录目标 Git 状态。无法判断目标时才询问。
2. 在目标目录之外建立临时 checkout，使用用户指定来源/ref，否则使用文档约定的默认分支。解析并记录实际 commit，随后都从同一 checkout 读取文件与运行命令，避免安装中途混用不同版本。
3. 完整读取该 checkout 的 `INSTALL.md`、对应 init/incognito skill 及其必要引用。无需提前安装入口 skill，也不依赖当前会话马上发现新技能。
4. 扩展只初始化 gitlink 固定的 Tina submodule。初始安装不用 `submodule update --remote`，也不把 Tina 升级作为隐含步骤；以后升级仍由扩展已有依赖更新流程完成。
5. 使用原有 installer 的普通或 incognito 模式。沿用其冲突保护，禁止自行覆盖托管内容或复制源仓库根 `AGENTS.md`。遇到具体冲突时再收集必要决策。
6. 按原有初始化 skill 验证完整载荷与 Git 差异，报告来源 commit、目标与结果。incognito 验证范围包括 tracked 内容、索引和安装前后 Git 状态。临时源码只在本次安装结束后清理。

该设计保留原有 `$tina-init`、`$tina-init-incognito` 及扩展的技能入口；一句话指南是新的获取路径。当前无须发布 npm 包或增加常驻下载器。

## OpenSpec 的隔离执行

npm 官方说明：`npm exec --package=<包及版本>` 将指定包的可执行文件加入所执行命令的 `PATH`；缺失包下载到 npm cache。`--` 结束 npm 参数解析，`--yes` 跳过 npm 的下载确认，带版本的 package 仅匹配同名同版本本地依赖。[npm exec 官方文档](https://docs.npmjs.com/cli/v11/commands/npm-exec/#description)

因此可以从 bundle 的 `dependencies.env` 读取 OpenSpec pin，再用下列形式启动绝对路径 installer。脚本及其子进程继承该环境，这是无需全局安装 OpenSpec 的建议实现：

```sh
npm exec --yes --package="@fission-ai/openspec@$openspec_version" -- "$bundle_root/install.sh" "$target"
```

npm 同时保留本地 package executables 在 `PATH`，所以应从隔离 checkout/临时目录运行，并在同一环境检查实际 `openspec --version`。后续验证用相同 pin；命令退出后不能假设下一个独立 shell 仍能直接调用该可执行文件。[npm exec PATH 与版本规则](https://docs.npmjs.com/cli/v11/commands/npm-exec/#description)

这只是移除全局软件前置条件，仍需要网络、Git、适合 pinned OpenSpec 的 Node/npm，以及目标目录写权限。具体冲突与失败按已有 installer 返回的证据处理。
