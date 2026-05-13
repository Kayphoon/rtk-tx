# rtk-tx

面向 Tencent CodeBuddy Code 的 `rtk-ai/rtk` fork 分支。

`rtk-tx` 不是普通 `rtk` 的重新包装，也不是 crates.io 上另一个同名工具。这个仓库保留 upstream `rtk` 的命令输出压缩能力，但把二进制名、rewrite 输出、CodeBuddy hook/init、tracking 路径和 telemetry 默认行为都调整为 CodeBuddy 优先。

## 这个 fork 为什么存在

upstream `rtk` 是一个通用 CLI proxy，用来把 `git`、`cargo`、`npm`、`pytest` 等命令输出压缩后再交给 LLM，减少 token 消耗。

这个 fork 的目标更窄：

- 给 **Tencent CodeBuddy Code** 提供一等 hook 支持。
- 生成独立二进制 **`rtk-tx`**，避免和普通 `rtk` 混用。
- 让 rewrite 后的命令明确显示为 `rtk-tx ...`。
- 保留本地 `gain` / tracking，但默认不发送 remote telemetry。
- 让 README 默认用中文解释这个 fork 的特殊性。

## 和普通 rtk 有什么不同

| 项目 | 普通 upstream `rtk` | 这个 fork `rtk-tx` |
|---|---|---|
| 仓库关系 | `rtk-ai/rtk` upstream | `Kayphoon/rtk-tx`，保留 GitHub fork 关系 |
| 二进制名 | `rtk` | `rtk-tx` |
| 版本命令 | `rtk --version` | `rtk-tx --version` |
| rewrite 输出 | `rtk git status` | `rtk-tx git status` |
| CodeBuddy hook | 非重点路径 | `rtk-tx hook codebuddy` |
| CodeBuddy init | 非重点路径 | `rtk-tx init --codebuddy` / `rtk-tx init -g --codebuddy` |
| WorkBuddy hook | 新增支持 | `rtk-tx hook workbuddy` |
| WorkBuddy init | 新增支持 | `rtk-tx init --workbuddy` / `rtk-tx init -g --workbuddy` |
| tracking DB override | upstream legacy variable | `RTK_TX_DB_PATH` |
| gain 命令 | `rtk gain` | `rtk-tx gain` |
| remote telemetry | 按 upstream 行为 | v1 默认禁用 / 无远程发送路径 |

结论：你的日常命令应该使用 **`rtk-tx ...`**，而不是普通 **`rtk ...`**。

## 能不能构建独立 rtk-tx 版本

可以。这个 fork 的 Cargo package / binary 已经是 `rtk-tx`。

本地开发构建：

```bash
cargo build
./target/debug/rtk-tx --version
```

release 构建：

```bash
cargo build --release
./target/release/rtk-tx --version
```

安装到本机 PATH：

```bash
cargo install --path .
rtk-tx --version
```

也可以等 GitHub Release 产物生成后，通过仓库脚本下载安装：

```bash
curl -fsSL https://raw.githubusercontent.com/Kayphoon/rtk-tx/master/install.sh | sh
```

指定版本：

```bash
RTK_TX_VERSION=v0.34.3 sh ./install.sh
```

安装脚本会从 `Kayphoon/rtk-tx` 的 GitHub Releases 下载 `rtk-tx-${target}.tar.gz`，并在 release 提供 `checksums.txt` 时校验 sha256。

安装后，普通命令示例：

```bash
rtk-tx git status
rtk-tx cargo test
rtk-tx rewrite "git status"
```

`rtk-tx rewrite "git status"` 应输出：

```text
rtk-tx git status
```

## 有没有单独的 rtk-tx gain

有。`gain` 是 `rtk-tx` 二进制下面的子命令：

```bash
rtk-tx gain
rtk-tx gain --history
rtk-tx gain --daily
rtk-tx gain --all --format json
```

`rtk-tx gain` 使用 `rtk-tx` 的本地 SQLite tracking 数据。默认数据目录也已经从普通 `rtk` 迁移到 `rtk-tx` 命名空间。

如果你想强制和普通 `rtk` 完全隔离，可以显式设置：

```bash
export RTK_TX_DB_PATH="$HOME/.local/share/rtk-tx/history.db"
rtk-tx gain
```

测试或临时验证时可以使用独立 DB：

```bash
RTK_TX_DB_PATH=/tmp/rtk-tx-check.db rtk-tx gain
```

## CodeBuddy 用法

项目级初始化：

```bash
rtk-tx init --codebuddy
```

全局初始化：

```bash
rtk-tx init -g --codebuddy
```

CodeBuddy hook 命令：

```bash
rtk-tx hook codebuddy
```

CodeBuddy settings 中使用的是 Claude-compatible hook 结构：

- hook event: `PreToolUse`
- matcher: `Bash`
- command: `rtk-tx hook codebuddy`
- rewrite output: `hookSpecificOutput.updatedInput.command`

这个 fork v1 不会 patch `.codebuddy/settings.local.json`。如果 CodeBuddy 检测到外部 settings 修改，可能还需要你在 CodeBuddy 的 `/hooks` 面板里确认。

## WorkBuddy 用法

项目级初始化：

```bash
rtk-tx init --workbuddy
```

全局初始化：

```bash
rtk-tx init -g --workbuddy
```

WorkBuddy hook 命令：

```bash
rtk-tx hook workbuddy
```

WorkBuddy settings 使用 Claude-compatible hook 结构（与 CodeBuddy 相同）：

- hook event: `PreToolUse`
- matcher: `Bash|execute_command`（WorkBuddy IDE 模式使用 `execute_command` 作为 tool_name）
- command: `rtk-tx hook workbuddy`
- rewrite output: `hookSpecificOutput.updatedInput.command`

这个 fork v1 不会 patch `.workbuddy/settings.local.json`。

## Privacy / telemetry

`rtk-tx` v1 不发送 remote telemetry：

- 不编译默认远程 telemetry endpoint。
- 正常 hook / init / rewrite 流程不会发网络 telemetry。
- `rtk-tx telemetry forget` 只处理本地 salt / marker / tracking DB。
- 本地 SQLite tracking 保留，用于 `rtk-tx gain`。

## 保留了哪些 upstream 能力

这个 fork 仍继承 upstream `rtk` 的核心命令过滤能力，包括但不限于：

- `git` / `gh`
- `cargo`
- `npm` / `pnpm` / `npx`
- `vitest` / `jest` / `playwright`
- `pytest` / `ruff` / `mypy`
- `docker` / `kubectl` / `aws`
- `grep` / `find` / `read` / `ls` / `tree`

也就是说，`rtk-tx` 的重点不是删掉 upstream 功能，而是在保留这些功能的基础上，做 CodeBuddy 专属适配。

## License / attribution

这个仓库派生自 [rtk-ai/rtk](https://github.com/rtk-ai/rtk)，必须继续保留 upstream 的 LICENSE / copyright / attribution 信息。

你可以把这个 fork 作为 `rtk-tx` 独立维护，但不能把 upstream license notice 删除后当作纯原创项目发布。
