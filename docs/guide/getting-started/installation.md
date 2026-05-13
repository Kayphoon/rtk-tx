---
title: Installation
description: Install rtk-tx from source/local checkout and verify the correct version
sidebar:
  order: 1
---

# Installation

## Name collision warning

Two unrelated projects share the name `rtk`. Make sure you install the right one:

- **Rust Token Killer** (`rtk-ai/rtk`) — this project, a token-saving CLI proxy
- **Rust Type Kit** (`reachingforthejack/rtk`) — a different tool for generating Rust types

The easiest way to verify you have the correct one: run `rtk-tx gain`. It should display token savings stats. If it returns "command not found", you either have the wrong package or rtk-tx is not installed.

## Check before installing

```bash
rtk-tx --version   # should print: rtk-tx x.y.z
rtk-tx gain        # should show token savings stats
```

If both commands work, rtk-tx is already installed. Skip to [Project initialization](#project-initialization).

## Source/local install

:::caution[Name collision risk]
`cargo install rtk` may install **Rust Type Kit** instead of Rust Token Killer — two unrelated projects share the same crate name. Use the local `rtk-tx` fork checkout path:
:::

```bash
cargo install --path .
```

This fork uses source/local install wording until package-manager or release publishing for `rtk-tx` is available in your environment.

## Verify installation

```bash
rtk-tx --version   # rtk-tx x.y.z
rtk-tx gain        # token savings dashboard
```

If `rtk-tx gain` fails but `rtk-tx --version` succeeds, remove the stale install first:

```bash
cargo uninstall rtk-tx
```

Then reinstall using one of the methods above.

## Project initialization

Run once per project to enable the Claude Code hook:

```bash
rtk-tx init
```

For a global install that patches `settings.json` automatically:

```bash
rtk-tx init --global
```

For CodeBuddy Code, patch CodeBuddy settings instead:

```bash
rtk-tx init --codebuddy       # project: <project-root>/.codebuddy/settings.json
rtk-tx init -g --codebuddy    # global: ~/.codebuddy/settings.json
rtk-tx hook codebuddy         # native CodeBuddy hook adapter
```

CodeBuddy Code hooks are Claude-compatible: `rtk-tx` writes `hooks.PreToolUse` with matcher `Bash` and command `rtk-tx hook codebuddy`. Rewrites are returned through `hookSpecificOutput.updatedInput.command`, so `rtk-tx rewrite "git status"` produces `rtk-tx git status`. `rtk-tx` v1 does **not** patch `.codebuddy/settings.local.json`.

After external settings changes, CodeBuddy may require you to review or approve the hook configuration in its `/hooks` panel.

For WorkBuddy, patch WorkBuddy settings instead:

```bash
rtk-tx init --workbuddy       # project: <project-root>/.workbuddy/settings.json
rtk-tx init -g --workbuddy    # global: ~/.workbuddy/settings.json
rtk-tx hook workbuddy         # native WorkBuddy hook adapter
```

WorkBuddy hooks are Claude-compatible: `rtk-tx` writes `hooks.PreToolUse` with matcher `Bash|execute_command` (WorkBuddy IDE mode uses `execute_command` as the tool_name) and command `rtk-tx hook workbuddy`. Rewrites are returned through `hookSpecificOutput.updatedInput.command`. `rtk-tx` v1 does **not** patch `.workbuddy/settings.local.json`.

## Uninstall

```bash
rtk-tx init -g --uninstall    # remove hook, RTK.md, and settings.json entry
cargo uninstall rtk-tx         # remove binary (if installed via Cargo)
```
