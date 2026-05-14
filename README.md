# rtk-tx

命令输出压缩工具，为 AI 编程助手瘦身 token 消耗。基于 [rtk-ai/rtk](https://github.com/rtk-ai/rtk) fork，提供 CodeBuddy / WorkBuddy 一等 hook 支持。

`rtk-tx` 在执行命令后压缩输出（git diff、cargo test、pytest 等），让 LLM 拿到精简但关键的信息，而非完整终端 dump。

## 安装

一键安装：

```bash
curl -fsSL https://raw.githubusercontent.com/Kayphoon/rtk-tx/master/install.sh | sh
```

指定版本：

```bash
RTK_TX_VERSION=v0.38.0 sh ./install.sh
```

从源码构建：

```bash
cargo build --release
./target/release/rtk-tx --version
```

安装到 PATH：

```bash
cargo install --path .
```

## 快速上手

安装完成后，直接在命令前加 `rtk-tx`：

```bash
rtk-tx git status          # 压缩 git 输出
rtk-tx cargo test          # 压缩 cargo 输出
rtk-tx pytest tests/       # 压缩 pytest 输出
```

查看 rewrite 后的命令：

```bash
rtk-tx rewrite "git status"
# 输出: rtk-tx git status
```

## AI 编程助手集成

### CodeBuddy

初始化（项目级）：

```bash
rtk-tx init --codebuddy
```

初始化（全局）：

```bash
rtk-tx init -g --codebuddy
```

`init` 完成后，CodeBuddy 会在每次执行 bash 命令前自动调用 `rtk-tx hook codebuddy`，将命令改写为 `rtk-tx <原始命令>`，从而压缩输出。你不需要手动运行这个命令。

hook 配置（Claude-compatible）：

| 字段 | 值 |
|---|---|
| event | `PreToolUse` |
| matcher | `Bash` |
| command | `rtk-tx hook codebuddy` |
| rewrite | `hookSpecificOutput.updatedInput.command` |

> v1 不会自动 patch `.codebuddy/settings.local.json`，如需生效请在 CodeBuddy `/hooks` 面板确认。

### WorkBuddy

初始化（项目级）：

```bash
rtk-tx init --workbuddy
```

初始化（全局）：

```bash
rtk-tx init -g --workbuddy
```

与 CodeBuddy 同理，`init` 完成后 WorkBuddy 会在执行命令前自动调用 `rtk-tx hook workbuddy` 进行改写，无需手动运行。

hook 配置（Claude-compatible）：

| 字段 | 值 |
|---|---|
| event | `PreToolUse` |
| matcher | `Bash\|execute_command` |
| command | `rtk-tx hook workbuddy` |
| rewrite | `hookSpecificOutput.updatedInput.command` |

> v1 不会自动 patch `.workbuddy/settings.local.json`。

## 其他命令

### gain — 本地统计

```bash
rtk-tx gain                      # 当日统计
rtk-tx gain --history            # 历史统计
rtk-tx gain --daily              # 按日统计
rtk-tx gain --all --format json  # 全部输出为 JSON
```

数据存储在本地 SQLite，默认位于 `rtk-tx` 命名空间。如需指定路径：

```bash
export RTK_TX_DB_PATH="$HOME/.local/share/rtk-tx/history.db"
```

### telemetry — 隐私管理

```bash
rtk-tx telemetry forget    # 清除本地 salt / marker / tracking
```

## 支持的命令

继承 upstream 全部过滤能力：

| 类别 | 命令 |
|---|---|
| Git | `git`, `gh` |
| Rust | `cargo` |
| Node | `npm`, `pnpm`, `npx` |
| 测试 | `vitest`, `jest`, `playwright`, `pytest` |
| Python | `ruff`, `mypy` |
| 云/容器 | `docker`, `kubectl`, `aws` |
| 通用 | `grep`, `find`, `read`, `ls`, `tree` |

## 与 upstream 的区别

| 项目 | upstream `rtk` | `rtk-tx` |
|---|---|---|
| 二进制名 | `rtk` | `rtk-tx` |
| rewrite 输出 | `rtk git status` | `rtk-tx git status` |
| CodeBuddy / WorkBuddy hook | — | `rtk-tx hook <agent>` |
| CodeBuddy / WorkBuddy init | — | `rtk-tx init --<agent>` |
| tracking DB | upstream 默认路径 | `RTK_TX_DB_PATH` |
| 远程 telemetry | 按 upstream 行为 | 默认禁用 |

## 隐私

- 不编译远程 telemetry endpoint
- hook / init / rewrite 流程不产生网络请求
- `telemetry forget` 仅处理本地数据
- 本地 SQLite tracking 保留，用于 `gain` 统计

## 许可证

派生自 [rtk-ai/rtk](https://github.com/rtk-ai/rtk)，必须保留 upstream LICENSE / copyright / attribution 信息。
