# rtk-tx

命令输出压缩工具，为 AI 编程助手瘦身 token 消耗。

基于 [rtk-ai/rtk](https://github.com/rtk-ai/rtk) fork，提供 CodeBuddy / WorkBuddy 一等 hook 支持。

## 为什么需要它

AI 编程助手每执行一条命令，完整输出直接灌进上下文。一次 `cargo test` 动辄数千行，`git diff` 轻松上万 token —— 大部分是噪音。

rtk-tx 在输出到达 LLM 之前自动压缩：

| 操作 | 原始 | 压缩后 | 节省 |
|------|------|--------|------|
| `git status` | ~3,000 tokens | ~600 | 80% |
| `git diff` | ~10,000 tokens | ~2,500 | 75% |
| `cargo test` / `npm test` | ~25,000 tokens | ~2,500 | 90% |
| `ls` / `tree` | ~2,000 tokens | ~400 | 80% |
| `grep` / `rg` | ~16,000 tokens | ~3,200 | 80% |

## 工作原理

```
  AI 助手  ──git status──>  shell  ──>  完整输出 (~3000 tokens)
     ^                                              |
     |                 没有 rtk-tx                   |
     +──────────────────────────────────────────────+

  AI 助手  ──git status──>  rtk-tx  ──>  git  ──>  压缩输出 (~600 tokens)
     ^                                              |
     |                 使用 rtk-tx                   |
     +──────────────────────────────────────────────+
```

四种压缩策略：智能过滤 → 分组聚合 → 截断保留 → 去重合并

## 安装

```bash
curl -fsSL https://raw.githubusercontent.com/Kayphoon/rtk-tx/master/install.sh | sh
```

验证：

```bash
rtk-tx --version
```

其他安装方式：

```bash
# 指定版本
RTK_TX_VERSION=v0.38.0 sh ./install.sh

# 从源码
cargo install --path .
```

## AI 助手集成

安装 rtk-tx 后，只需一行 `init` 命令即可与 AI 助手联动：

### CodeBuddy

```bash
rtk-tx init --codebuddy      # 项目级
rtk-tx init -g --codebuddy   # 全局
```

### WorkBuddy

```bash
rtk-tx init --workbuddy      # 项目级
rtk-tx init -g --workbuddy   # 全局
```

`init` 完成后，AI 助手会在每次执行命令前自动将命令改写为 `rtk-tx <原始命令>`，无需任何额外操作。

## 支持的命令

| 类别 | 命令 |
|------|------|
| Git | `git`, `gh` |
| Rust | `cargo` |
| Node | `npm`, `pnpm`, `npx` |
| 测试 | `vitest`, `jest`, `playwright`, `pytest` |
| Python | `ruff`, `mypy` |
| 云/容器 | `docker`, `kubectl`, `aws` |
| 通用 | `grep`, `find`, `read`, `ls`, `tree` |

## 其他功能

```bash
rtk-tx gain                      # 查看 token 节省统计
rtk-tx gain --history            # 历史统计
rtk-tx gain --daily              # 按日统计
rtk-tx gain --all --format json  # JSON 输出

rtk-tx telemetry forget          # 清除本地追踪数据
```

统计数据库路径：

```bash
export RTK_TX_DB_PATH="$HOME/.local/share/rtk-tx/history.db"
```

## 与 upstream 的区别

| | upstream `rtk` | `rtk-tx` |
|---|---|---|
| 二进制名 | `rtk` | `rtk-tx` |
| CodeBuddy hook | — | `rtk-tx hook codebuddy` |
| WorkBuddy hook | — | `rtk-tx hook workbuddy` |
| CodeBuddy / WorkBuddy init | — | `rtk-tx init --<agent>` |
| 远程 telemetry | 按 upstream 行为 | 默认禁用 |

## 隐私

- 不编译远程 telemetry endpoint
- hook / init 流程不产生网络请求
- `telemetry forget` 仅处理本地数据
- 本地 SQLite 保留，用于 `gain` 统计

## 许可证

派生自 [rtk-ai/rtk](https://github.com/rtk-ai/rtk)，必须保留 upstream LICENSE / copyright / attribution 信息。
