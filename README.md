# rtk-tx

面向 Tencent CodeBuddy Code 的 rtk 派生 fork 项目。

这个仓库是 [rtk-ai/rtk](https://github.com/rtk-ai/rtk) 的 fork，专门为 **Tencent CodeBuddy Code** 场景做了定向改造。它保留了 upstream rtk 的核心过滤能力，但默认行为、集成入口和文档重心都更偏向 CodeBuddy 的实际使用方式。

## 这个仓库的特殊性

与通用 rtk 相比，这个 fork 的重点是：

- **CodeBuddy 一等支持**：`rtk-tx hook codebuddy` 与 `rtk-tx init --codebuddy` / `rtk-tx init -g --codebuddy` 是重点集成路径。
- **输出以 `rtk-tx` 为主**：rewrite 输出默认为 `rtk-tx ...`，而不是 upstream 的 `rtk ...`。
- **remote telemetry 默认关闭**：`rtk-tx` v1 不发送远程 telemetry，保留本地 SQLite tracking / `rtk-tx gain`。
- **本地 tracking 优先使用 `RTK_TX_DB_PATH`**：环境变量控制本地数据库路径，`RTK_DB_PATH` 仅作为 deprecated fallback。
- **保留 inherited command filters**：继续保留 upstream rtk 已有的命令过滤能力，不随意删减。

这个仓库更适合：

- 主要在 **CodeBuddy Code** 环境里工作
- 希望保留 rtk 的过滤收益，但默认面向 CodeBuddy
- 希望 remote telemetry 默认关闭，只保留本地统计
- 希望 README 直接讲清楚 “这个仓库为什么存在” 以及 “它和 upstream rtk 有什么不同”

## 与 upstream rtk 的关系

这个仓库来自 upstream `rtk-ai/rtk`，因此仍然保留原始开源项目相关的 license / attribution 要求。  
如果你修改或再发布这个项目，请继续遵守原始 LICENSE 条款，不要把 upstream 版权信息直接删掉。

## 默认语言说明

这个 fork 的 README 默认以中文说明，原因很简单：  
它不是一个通用文档项目，而是为了明确表达 **“这个仓库为什么存在”** 以及 **“它和 upstream rtk 有什么不同”**。

---

rtk-tx filters and compresses command outputs before they reach your LLM context. Single Rust binary, 100+ supported commands, <10ms overhead.

## Token Savings (30-min Claude Code Session)

| Operation | Frequency | Standard | rtk-tx | Savings |
|-----------|-----------|----------|-----|---------|
| `ls` / `tree` | 10x | 2,000 | 400 | -80% |
| `cat` / `read` | 20x | 40,000 | 12,000 | -70% |
| `grep` / `rg` | 8x | 16,000 | 3,200 | -80% |
| `git status` | 10x | 3,000 | 600 | -80% |
| `git diff` | 5x | 10,000 | 2,500 | -75% |
| `git log` | 5x | 2,500 | 500 | -80% |
| `git add/commit/push` | 8x | 1,600 | 120 | -92% |
| `cargo test` / `npm test` | 5x | 25,000 | 2,500 | -90% |
| `ruff check` | 3x | 3,000 | 600 | -80% |
| `pytest` | 4x | 8,000 | 800 | -90% |
| `go test` | 3x | 6,000 | 600 | -90% |
| `docker ps` | 3x | 900 | 180 | -80% |
| **Total** | | **~118,000** | **~23,900** | **-80%** |

> Estimates based on medium-sized TypeScript/Rust projects. Actual savings vary by project size.

## Installation

### Source/local install

```bash
cargo install --path .
```

> This fork documents source/local installation until package-manager or release publishing for `rtk-tx` is available in your environment.

### Verify Installation

```bash
rtk-tx --version   # Should show "rtk-tx 0.34.3"
rtk-tx gain        # Should show token savings stats
```

> **Name collision warning**: Another project named "rtk" (Rust Type Kit) exists on crates.io. If `rtk-tx gain` fails, you have the wrong package or `rtk-tx` is missing. Use `cargo install --path .` from this fork checkout.

## Quick Start

```bash
# 1. Install for your AI tool
rtk-tx init -g                     # Claude Code / Copilot (default)
rtk-tx init --codebuddy            # CodeBuddy Code (project settings)
rtk-tx init -g --codebuddy         # CodeBuddy Code (global settings)
rtk-tx init -g --gemini            # Gemini CLI
rtk-tx init -g --codex             # Codex (OpenAI)
rtk-tx init -g --agent cursor      # Cursor
rtk-tx init --agent windsurf       # Windsurf
rtk-tx init --agent cline          # Cline / Roo Code
rtk-tx init --agent kilocode       # Kilo Code
rtk-tx init --agent antigravity    # Google Antigravity
rtk-tx init --agent hermes         # Hermes

# 2. Restart your AI tool, then test
git status  # Automatically rewritten to rtk-tx git status
rtk-tx rewrite "git status"  # -> rtk-tx git status
```

Hook-based agents rewrite Bash commands (e.g., `git status` -> `rtk-tx git status`) before execution. Plugin-based agents, including Hermes, use their plugin API to rewrite commands before execution. The agent receives compact output without needing to call `rtk-tx` explicitly.

### CodeBuddy Code setup

CodeBuddy Code uses Claude-compatible hooks. Install the native adapter with:

```bash
rtk-tx init --codebuddy       # project: <project-root>/.codebuddy/settings.json
rtk-tx init -g --codebuddy    # global: ~/.codebuddy/settings.json
rtk-tx hook codebuddy         # hook adapter used by CodeBuddy settings
```

The settings entry uses `hooks.PreToolUse`, matcher `Bash`, and command `rtk-tx hook codebuddy`. When it rewrites a command, the hook emits `hookSpecificOutput.updatedInput.command` (for example, `rtk-tx rewrite "git status"` returns `rtk-tx git status`). `rtk-tx` v1 does **not** patch `.codebuddy/settings.local.json`.

After external settings changes, CodeBuddy may require you to review or approve the hook configuration in its `/hooks` panel before the hook runs.

**Important:** the hook only runs on Bash tool calls. Claude Code built-in tools like `Read`, `Grep`, and `Glob` do not pass through the Bash hook, so they are not auto-rewritten. To get RTK's compact output for those workflows, use shell commands (`cat`/`head`/`tail`, `rg`/`grep`, `find`) or call `rtk-tx read`, `rtk-tx grep`, or `rtk-tx find` directly.

## How It Works

```
  Without rtk-tx:                                    With rtk-tx:

  Claude  --git status-->  shell  -->  git         Claude  --git status-->  RTK  -->  git
    ^                                   |            ^                      |          |
    |        ~2,000 tokens (raw)        |            |   ~200 tokens        | filter   |
    +-----------------------------------+            +------- (filtered) ---+----------+
```

Four strategies applied per command type:

1. **Smart Filtering** - Removes noise (comments, whitespace, boilerplate)
2. **Grouping** - Aggregates similar items (files by directory, errors by type)
3. **Truncation** - Keeps relevant context, cuts redundancy
4. **Deduplication** - Collapses repeated log lines with counts

## Commands

### Files
```bash
rtk-tx ls .                        # Token-optimized directory tree
rtk-tx read file.rs                # Smart file reading
rtk-tx read file.rs -l aggressive  # Signatures only (strips bodies)
rtk-tx smart file.rs               # 2-line heuristic code summary
rtk-tx find "*.rs" .               # Compact find results
rtk-tx grep "pattern" .            # Grouped search results
rtk-tx diff file1 file2            # Condensed diff
```

### Git
```bash
rtk-tx git status                  # Compact status
rtk-tx git log -n 10               # One-line commits
rtk-tx git diff                    # Condensed diff
rtk-tx git add                     # -> "ok"
rtk-tx git commit -m "msg"         # -> "ok abc1234"
rtk-tx git push                    # -> "ok main"
rtk-tx git pull                    # -> "ok 3 files +10 -2"
```

### GitHub CLI
```bash
rtk-tx gh pr list                  # Compact PR listing
rtk-tx gh pr view 42               # PR details + checks
rtk-tx gh issue list               # Compact issue listing
rtk-tx gh run list                 # Workflow run status
```

### Test Runners
```bash
rtk-tx jest                        # Jest compact (failures only)
rtk-tx vitest                      # Vitest compact (failures only)
rtk-tx playwright test             # E2E results (failures only)
rtk-tx pytest                      # Python tests (-90%)
rtk-tx go test                     # Go tests (NDJSON, -90%)
rtk-tx cargo test                  # Cargo tests (-90%)
rtk-tx rake test                   # Ruby minitest (-90%)
rtk-tx rspec                       # RSpec tests (JSON, -60%+)
rtk-tx err <cmd>                   # Filter errors only from any command
rtk-tx test <cmd>                  # Generic test wrapper - failures only (-90%)
```

### Build & Lint
```bash
rtk-tx lint                        # ESLint grouped by rule/file
rtk-tx lint biome                  # Supports other linters
rtk-tx tsc                         # TypeScript errors grouped by file
rtk-tx next build                  # Next.js build compact
rtk-tx prettier --check .          # Files needing formatting
rtk-tx cargo build                 # Cargo build (-80%)
rtk-tx cargo clippy                # Cargo clippy (-80%)
rtk-tx ruff check                  # Python linting (JSON, -80%)
rtk-tx golangci-lint run           # Go linting (JSON, -85%)
rtk-tx rubocop                     # Ruby linting (JSON, -60%+)
```

### Package Managers
```bash
rtk-tx pnpm list                   # Compact dependency tree
rtk-tx pip list                    # Python packages (auto-detect uv)
rtk-tx pip outdated                # Outdated packages
rtk-tx bundle install              # Ruby gems (strip Using lines)
rtk-tx prisma generate             # Schema generation (no ASCII art)
```

### AWS
```bash
rtk-tx aws sts get-caller-identity # One-line identity
rtk-tx aws ec2 describe-instances  # Compact instance list
rtk-tx aws lambda list-functions   # Name/runtime/memory (strips secrets)
rtk-tx aws logs get-log-events     # Timestamped messages only
rtk-tx aws cloudformation describe-stack-events  # Failures first
rtk-tx aws dynamodb scan           # Unwraps type annotations
rtk-tx aws iam list-roles          # Strips policy documents
rtk-tx aws s3 ls                   # Truncated with tee recovery
```

### Containers
```bash
rtk-tx docker ps                   # Compact container list
rtk-tx docker images               # Compact image list
rtk-tx docker logs <container>     # Deduplicated logs
rtk-tx docker compose ps           # Compose services
rtk-tx kubectl pods                # Compact pod list
rtk-tx kubectl logs <pod>          # Deduplicated logs
rtk-tx kubectl services            # Compact service list
```

### Data & Analytics
```bash
rtk-tx json config.json            # Structure without values
rtk-tx deps                        # Dependencies summary
rtk-tx env -f AWS                  # Filtered env vars
rtk-tx log app.log                 # Deduplicated logs
rtk-tx curl <url>                  # Truncate + save full output
rtk-tx wget <url>                  # Download, strip progress bars
rtk-tx summary <long command>      # Heuristic summary
rtk-tx proxy <command>             # Raw passthrough + tracking
```

### Token Savings Analytics
```bash
rtk-tx gain                        # Summary stats
rtk-tx gain --graph                # ASCII graph (last 30 days)
rtk-tx gain --history              # Recent command history
rtk-tx gain --daily                # Day-by-day breakdown
rtk-tx gain --all --format json    # JSON export for dashboards

rtk-tx discover                    # Find missed savings opportunities
rtk-tx discover --all --since 7    # All projects, last 7 days

rtk-tx session                     # Show RTK adoption across recent sessions
```

## Global Flags

```bash
-u, --ultra-compact    # ASCII icons, inline format (extra token savings)
-v, --verbose          # Increase verbosity (-v, -vv, -vvv)
```

## Examples

**Directory listing:**
```
# ls -la (45 lines, ~800 tokens)        # rtk-tx ls (12 lines, ~150 tokens)
drwxr-xr-x  15 user staff 480 ...       my-project/
-rw-r--r--   1 user staff 1234 ...       +-- src/ (8 files)
...                                      |   +-- main.rs
                                         +-- Cargo.toml
```

**Git operations:**
```
# git push (15 lines, ~200 tokens)       # rtk-tx git push (1 line, ~10 tokens)
Enumerating objects: 5, done.             ok main
Counting objects: 100% (5/5), done.
Delta compression using up to 8 threads
...
```

**Test output:**
```
# cargo test (200+ lines on failure)     # rtk-tx test cargo test (~20 lines)
running 15 tests                          FAILED: 2/15 tests
test utils::test_parse ... ok               test_edge_case: assertion failed
test utils::test_format ... ok              test_overflow: panic at utils.rs:18
...
```

## Auto-Rewrite Hook

The most effective way to use rtk-tx. The hook transparently intercepts Bash commands and rewrites them to rtk-tx equivalents before execution.

**Result**: 100% rtk-tx adoption across all conversations and subagents, zero token overhead.

**Scope note:** this only applies to Bash tool calls. Claude Code built-in tools such as `Read`, `Grep`, and `Glob` bypass the hook, so use shell commands or explicit `rtk-tx` commands when you want filtering there.

### Setup

```bash
rtk-tx init -g                 # Install hook + RTK.md (recommended)
rtk-tx init --codebuddy        # CodeBuddy project hook in <project-root>/.codebuddy/settings.json
rtk-tx init -g --codebuddy     # CodeBuddy global hook in ~/.codebuddy/settings.json
rtk-tx init -g --opencode      # OpenCode plugin (instead of Claude Code)
rtk-tx init -g --auto-patch    # Non-interactive (CI/CD)
rtk-tx init -g --hook-only     # Hook only, no RTK.md
rtk-tx init --show             # Verify installation
```

After install, **restart Claude Code** or your target agent. For CodeBuddy, also check the `/hooks` panel if prompted to review externally changed hook settings.

## Windows

rtk-tx works on Windows with some limitations. The Claude auto-rewrite hook (`rtk-tx-rewrite.sh`) requires a Unix shell, so on native Windows rtk-tx falls back to **CLAUDE.md injection mode** — your AI assistant receives rtk-tx instructions but commands are not rewritten automatically.

### Recommended: WSL (full support)

For the best experience, use [WSL](https://learn.microsoft.com/en-us/windows/wsl/install) (Windows Subsystem for Linux). Inside WSL, RTK works exactly like Linux — full hook support, auto-rewrite, everything:

```bash
# Inside a local rtk-tx checkout
cargo install --path .
rtk-tx init -g
```

### Native Windows (limited support)

On native Windows (cmd.exe / PowerShell), RTK filters work but the hook does not auto-rewrite commands:

```powershell
# 1. Build or install rtk-tx.exe from this fork and add it to your PATH
# 2. Initialize (falls back to CLAUDE.md injection)
rtk-tx init -g
# 3. Use rtk-tx explicitly
rtk-tx cargo test
rtk-tx git status
```

**Important**: Do not double-click `rtk-tx.exe` — it is a CLI tool that prints usage and exits immediately. Always run it from a terminal (Command Prompt, PowerShell, or Windows Terminal).

| Feature | WSL | Native Windows |
|---------|-----|----------------|
| Filters (cargo, git, etc.) | Full | Full |
| Auto-rewrite hook | Yes | No (CLAUDE.md fallback) |
| `rtk-tx init -g` | Hook mode | CLAUDE.md mode |
| `rtk-tx gain` / analytics | Full | Full |

## Supported AI Tools

rtk-tx supports 14 AI coding tools. Each integration rewrites shell commands to `rtk-tx` equivalents for 60-90% token savings where the agent supports command interception.

| Tool | Install | Method |
|------|---------|--------|
| **Claude Code** | `rtk-tx init -g` | PreToolUse hook (bash) |
| **CodeBuddy Code** | `rtk-tx init --codebuddy` / `rtk-tx init -g --codebuddy` | Claude-compatible `PreToolUse` hook (`rtk-tx hook codebuddy`) |
| **GitHub Copilot (VS Code)** | `rtk-tx init -g --copilot` | PreToolUse hook — transparent rewrite |
| **GitHub Copilot CLI** | `rtk-tx init -g --copilot` | PreToolUse deny-with-suggestion (CLI limitation) |
| **Cursor** | `rtk-tx init -g --agent cursor` | preToolUse hook (hooks.json) |
| **Gemini CLI** | `rtk-tx init -g --gemini` | BeforeTool hook |
| **Codex** | `rtk-tx init -g --codex` | AGENTS.md + RTK.md instructions |
| **Windsurf** | `rtk-tx init --agent windsurf` | .windsurfrules (project-scoped) |
| **Cline / Roo Code** | `rtk-tx init --agent cline` | .clinerules (project-scoped) |
| **OpenCode** | `rtk-tx init -g --opencode` | Plugin TS (tool.execute.before) |
| **OpenClaw** | `openclaw plugins install ./openclaw` | Plugin TS (before_tool_call) |
| **Hermes** | `rtk-tx init --agent hermes` | Python plugin (terminal command mutation via `rtk-tx rewrite`) |
| **Mistral Vibe** | Planned ([#800](https://github.com/rtk-ai/rtk/issues/800)) | Blocked on upstream |
| **Kilo Code** | `rtk-tx init --agent kilocode` | .kilocode/rules/rtk-rules.md (project-scoped) |
| **Google Antigravity** | `rtk-tx init --agent antigravity` | .agents/rules/antigravity-rtk-rules.md (project-scoped) |

For per-agent setup details, override controls, and graceful degradation, see the [Supported Agents guide](https://www.rtk-ai.app/guide/getting-started/supported-agents).

## Configuration

`~/.config/rtk-tx/config.toml` (macOS: `~/Library/Application Support/rtk-tx/config.toml`):

```toml
[hooks]
exclude_commands = ["curl", "playwright"]  # skip rewrite for these

[tee]
enabled = true          # save raw output on failure (default: true)
mode = "failures"       # "failures", "always", or "never"
```

When a command fails, rtk-tx saves the full unfiltered output so the LLM can read it without re-executing:

```
FAILED: 2/15 tests
[full output: ~/.local/share/rtk-tx/tee/1707753600_cargo_test.log]
```

For the full config reference (all sections, env vars, per-project filters), see the [Configuration guide](https://www.rtk-ai.app/guide/getting-started/configuration).

### Uninstall

```bash
rtk-tx init -g --uninstall     # Remove hook, RTK.md, settings.json entry
cargo uninstall rtk-tx          # Remove binary
```

## Documentation

- **[rtk-ai.app/guide](https://www.rtk-ai.app/guide)** — full user guide (installation, supported agents, what gets optimized, analytics, configuration, troubleshooting)
- **[INSTALL.md](INSTALL.md)** — detailed installation reference
- **[ARCHITECTURE.md](ARCHITECTURE.md)** — system design and technical decisions
- **[CONTRIBUTING.md](CONTRIBUTING.md)** — contribution guide
- **[SECURITY.md](SECURITY.md)** — security policy

## Privacy & Telemetry

rtk-tx v1 does **not** send remote telemetry. The startup telemetry hook is a no-op, no telemetry endpoint is compiled or called, and `rtk-tx telemetry forget` does not contact a server.

Local SQLite tracking remains available for `rtk-tx gain` and related analytics. By default it stores command savings data at `~/.local/share/rtk-tx/history.db`; override this with `RTK_TX_DB_PATH=/custom/path/history.db`. The legacy `RTK_DB_PATH` is accepted only as a deprecated fallback when `RTK_TX_DB_PATH` is unset.

**What is NOT sent:** source code, file paths, command arguments, secrets, environment variables, personal data, repository contents, usage metrics, device hashes, or erasure requests.

**Manage telemetry:**
```bash
rtk-tx telemetry status     # Check local status
rtk-tx telemetry enable     # Remote telemetry remains disabled/absent
rtk-tx telemetry disable    # Save disabled state locally
rtk-tx telemetry forget     # Delete local salt/marker/tracking DB only
```

**Override via environment:**
```bash
export RTK_TELEMETRY_DISABLED=1   # Harmless explicit block; remote telemetry is already disabled
export RTK_TX_DB_PATH=/custom/path/history.db  # Override local tracking DB
```

## Star History

<a href="https://www.star-history.com/?repos=rtk-ai%2Frtk&type=date&legend=top-left">
 <picture>
   <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/chart?repos=rtk-ai/rtk&type=date&theme=dark&legend=top-left" />
   <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/chart?repos=rtk-ai/rtk&type=date&legend=top-left" />
   <img alt="Star History Chart" src="https://api.star-history.com/chart?repos=rtk-ai/rtk&type=date&legend=top-left" />
 </picture>
</a>

## StarMapper

<a href="https://starmapper.bruniaux.com/rtk-ai/rtk">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://starmapper.bruniaux.com/api/map-image/rtk-ai/rtk?theme=dark" />
    <source media="(prefers-color-scheme: light)" srcset="https://starmapper.bruniaux.com/api/map-image/rtk-ai/rtk?theme=light" />
    <img alt="StarMapper" src="https://starmapper.bruniaux.com/api/map-image/rtk-ai/rtk" />
  </picture>
</a>

## Core team

- **Patrick Szymkowiak** — Founder
  [GitHub](https://github.com/pszymkowiak) · [LinkedIn](https://www.linkedin.com/in/patrick-szymkowiak/)
- **Florian Bruniaux** — Core contributor
  [GitHub](https://github.com/FlorianBruniaux) · [LinkedIn](https://www.linkedin.com/in/florian-bruniaux-43408b83/)
- **Adrien Eppling** — Core contributor
  [GitHub](https://github.com/aeppling) · [LinkedIn](https://www.linkedin.com/in/adrien-eppling/)

## Contributing

Contributions welcome! Please open an issue or PR on [GitHub](https://github.com/rtk-ai/rtk).

Join the community on [Discord](https://discord.gg/RySmvNF5kF).

## License

MIT License - see [LICENSE](LICENSE) for details.

## Disclaimer

See [DISCLAIMER.md](DISCLAIMER.md).
