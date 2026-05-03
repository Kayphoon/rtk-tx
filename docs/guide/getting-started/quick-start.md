---
title: Quick Start
description: Get RTK running in 5 minutes and see your first token savings
sidebar:
  order: 2
---

# Quick Start

This guide walks you through your first RTK commands after installation.

## Prerequisites

RTK is installed and verified:

```bash
rtk-tx --version   # rtk-tx x.y.z
rtk-tx gain        # shows token savings dashboard
```

If not, see [Installation](./installation.md).

## Step 1: Initialize for your AI assistant

```bash
# For Claude Code (global — applies to all projects)
rtk-tx init --global

# For a single project only
cd /your/project && rtk-tx init

# For CodeBuddy Code
rtk-tx init --codebuddy       # project: <project-root>/.codebuddy/settings.json
rtk-tx init -g --codebuddy    # global: ~/.codebuddy/settings.json
rtk-tx hook codebuddy         # native hook adapter
```

This installs the hook that automatically rewrites commands. Restart your AI assistant after this step.

CodeBuddy Code uses Claude-compatible Code hooks: `hooks.PreToolUse`, matcher `Bash`, and `hookSpecificOutput.updatedInput.command` from the `rtk-tx hook codebuddy` adapter. `rtk-tx` v1 patches `<project-root>/.codebuddy/settings.json` or `~/.codebuddy/settings.json`; it does **not** patch `.codebuddy/settings.local.json`. After external settings changes, CodeBuddy may require review/approval in its `/hooks` panel.

## Step 2: Use your tools normally

Once the hook is installed, nothing changes in how you work. Your AI assistant runs commands as usual — the hook intercepts them transparently and rewrites them before execution.

For example, when Claude Code or CodeBuddy runs `cargo test`, the hook rewrites it to `rtk-tx cargo test` before it executes. The LLM receives filtered output with only the failures — not 500 lines of passing tests. You can verify the rewrite directly: `rtk-tx rewrite "git status"` → `rtk-tx git status`.

RTK covers all major ecosystems — Git, Cargo/Rust, JavaScript, Python, Go, Ruby, .NET, Docker/Kubernetes, and more. See [What RTK Optimizes](../resources/what-rtk-covers.md) for the full list.

## Step 3: Check your savings

After a few commands, see how much was saved:

```bash
rtk-tx gain
```

```
Total commands : 12
Input tokens   : 45,230
Output tokens  : 4,890
Saved          : 40,340  (89.2%)
```

## Step 4: Unsupported commands

Commands RTK doesn't recognize run through passthrough — output is unchanged, usage is tracked:

```bash
rtk-tx proxy make install
```

## Next steps

- [What RTK Optimizes](../resources/what-rtk-covers.md) — all supported commands and savings by ecosystem
- [Supported agents](./supported-agents.md) — Claude Code, Cursor, Copilot, and more
- [Configuration](./configuration.md) — customize RTK behavior
