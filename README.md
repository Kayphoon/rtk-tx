# rtk-tx

面向 Tencent CodeBuddy Code 的 `rtk-ai/rtk` fork，提供一等 hook 支持、独立二进制和本地优先的 telemetry 策略。

---

## 概览

`rtk-tx` 保留 upstream `rtk` 的命令输出压缩能力，同时针对 CodeBuddy 场景做了以下调整：

- **独立二进制** `rtk-tx`，避免与普通 `rtk` 混用
- **一等 hook 支持**：CodeBuddy / WorkBuddy 初始化与 hook 命令
- **rewrite 输出**明确显示为 `rtk-tx ...`
- **本地优先**：保留 `gain` / tracking，默认禁用远程 telemetry
- **完全继承** upstream 过滤能力（git、cargo、npm、pytest、docker 等）

## 与 upstream 的区别

| 项目 | upstream `rtk` | `rtk-tx` |
|---|---|---|
| 二进制名 | `rtk` | `rtk-tx` |
| rewrite 输出 | `rtk git status` | `rtk-tx git status` |
| CodeBuddy hook | — | `rtk-tx hook codebuddy` |
| CodeBuddy init | — | `rtk-tx init --codebuddy` |
| WorkBuddy hook | — | `rtk-tx hook workbuddy` |
| WorkBuddy init | — | `rtk-tx init --workbuddy` |
| tracking DB | upstream 默认路径 | `RTK_TX_DB_PATH` |
| 远程 telemetry | 按 upstream 行为 | 默认禁用 |

## 安装

**一键安装：**

```bash
curl -fsSL https://raw.githubusercontent.com/Kayphoon/rtk-tx/master/install.sh | sh
```

指定版本：

```bash
RTK_TX_VERSION=v0.34.3 sh ./install.sh
```

**从源码构建：**

```bash
cargo build --release
./target/release/rtk-tx --version
```

**安装到 PATH：**

```bash
cargo install --path .
```

## 用法

### 命令压缩

```bash
rtk-tx git status        # 压缩 git 输出
rtk-tx cargo test        # 压缩 cargo 输出
rtk-tx rewrite "git status"  # 输出: rtk-tx git status
```

### CodeBuddy 集成

```bash
rtk-tx init --codebuddy       # 项目级初始化
rtk-tx init -g --codebuddy    # 全局初始化
rtk-tx hook codebuddy         # 执行 hook
```

CodeBuddy settings 使用 Claude-compatible hook 结构：

- **event**: `PreToolUse`
- **matcher**: `Bash`
- **command**: `rtk-tx hook codebuddy`
- **rewrite**: `hookSpecificOutput.updatedInput.command`

> v1 不会自动 patch `.codebuddy/settings.local.json`，如需生效请在 CodeBuddy `/hooks` 面板确认。

### WorkBuddy 集成

```bash
rtk-tx init --workbuddy       # 项目级初始化
rtk-tx init -g --workbuddy    # 全局初始化
rtk-tx hook workbuddy          # 执行 hook
```

WorkBuddy 同样使用 Claude-compatible hook 结构：

- **event**: `PreToolUse`
- **matcher**: `Bash|execute_command`
- **command**: `rtk-tx hook workbuddy`

> v1 不会自动 patch `.workbuddy/settings.local.json`。

### Gain 命令

```bash
rtk-tx gain                  # 当日统计
rtk-tx gain --history        # 历史统计
rtk-tx gain --daily          # 按日统计
rtk-tx gain --all --format json  # 全部输出为 JSON
```

`gain` 使用本地 SQLite tracking 数据，默认数据目录已迁移到 `rtk-tx` 命名空间。如需完全隔离：

```bash
export RTK_TX_DB_PATH="$HOME/.local/share/rtk-tx/history.db"
```

## 支持的命令过滤

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

## 隐私

`rtk-tx` v1 不发送远程 telemetry：

- 不编译默认远程 telemetry endpoint
- hook / init / rewrite 流程不产生网络请求
- `rtk-tx telemetry forget` 仅处理本地数据
- 本地 SQLite tracking 保留，用于 `gain` 统计

## 许可证

本仓库派生自 [rtk-ai/rtk](https://github.com/rtk-ai/rtk)，必须保留 upstream 的 LICENSE / copyright / attribution 信息。不可删除 upstream license notice 后作为纯原创项目发布。
