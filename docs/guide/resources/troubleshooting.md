---
title: Troubleshooting
description: Common RTK issues and how to fix them
sidebar:
  order: 2
---

# Troubleshooting

## `rtk gain` says "not a rtk command"

**Symptom:**
```bash
$ rtk gain
rtk-tx: 'gain' is not an rtk-tx command. See 'rtk-tx --help'.
```

**Cause:** You installed **Rust Type Kit** (`reachingforthejack/rtk`) instead of **Rust Token Killer** (`rtk-ai/rtk`). They share the same binary name.

**Fix:**
```bash
cargo uninstall rtk-tx
# From a local rtk-tx fork checkout
cargo install --path . --force
rtk-tx gain    # should now show token savings stats
```

## How to tell which rtk you have

| If `rtk gain`... | You have |
|------------------|----------|
| Shows token savings dashboard | Rust Token Killer ✅ |
| Returns "not a rtk command" | Rust Type Kit ❌ |

## AI assistant not using RTK

**Symptom:** Claude Code (or another agent) runs `cargo test` instead of `rtk cargo test`.

**Checklist:**

1. Verify RTK is installed:
   ```bash
   rtk-tx --version
   rtk-tx gain
   ```

2. Initialize the hook:
   ```bash
   rtk-tx init --global    # Claude Code
   rtk-tx init --global --cursor    # Cursor
   rtk-tx init --global --opencode  # OpenCode
   ```

3. Restart your AI assistant.

4. Verify hook status:
   ```bash
   rtk-tx init --show
   ```

5. Check `settings.json` has the hook registered (Claude Code):
   ```bash
   cat ~/.claude/settings.json | grep rtk
   ```

## RTK not found after `cargo install`

**Symptom:**
```bash
$ rtk-tx --version
zsh: command not found: rtk-tx
```

**Cause:** `~/.cargo/bin` is not in your PATH.

**Fix:**

For bash (`~/.bashrc`) or zsh (`~/.zshrc`):
```bash
export PATH="$HOME/.cargo/bin:$PATH"
```

For fish (`~/.config/fish/config.fish`):
```fish
set -gx PATH $HOME/.cargo/bin $PATH
```

Then reload:
```bash
source ~/.zshrc    # or ~/.bashrc
rtk-tx --version
```

## RTK on Windows

### Double-clicking rtk-tx.exe does nothing

**Symptom:** You double-click `rtk-tx.exe`, a terminal flashes and closes instantly.

**Cause:** RTK is a command-line tool. With no arguments, it prints usage and exits. The console window opens and closes before you can read anything.

**Fix:** Open a terminal first, then run RTK from there:
- Press `Win+R`, type `cmd`, press Enter
- Or open PowerShell or Windows Terminal
- Then run: `rtk-tx --version`

### Hook not working (no auto-rewrite)

**Symptom:** `rtk-tx init -g` shows "Falling back to --claude-md mode" on Windows.

**Cause:** The auto-rewrite hook (`rtk-rewrite.sh`) requires a Unix shell. Native Windows doesn't have one.

**Fix:** Use [WSL](https://learn.microsoft.com/en-us/windows/wsl/install) for full hook support:
```bash
# Inside WSL, from a local rtk-tx fork checkout
cargo install --path . --force
rtk-tx init -g    # full hook mode works in WSL
```

On native Windows, rtk-tx falls back to CLAUDE.md injection. Your AI assistant gets rtk-tx instructions but won't auto-rewrite commands. It can still use rtk-tx manually: `rtk-tx cargo test`, `rtk-tx git status`, etc.

### Node.js tools not found

**Symptom:**
```
rtk-tx vitest --run
Error: program not found
```

**Cause:** On Windows, Node.js tools are installed as `.CMD`/`.BAT` wrappers. Older RTK versions couldn't find them.

**Fix:** Reinstall rtk-tx from the local fork checkout:
```bash
cargo install --path . --force
rtk-tx --version    # should be 0.23.1+
```

## Compilation error during installation

```bash
rustup update stable
rustup default stable
cargo clean
cargo build --release
cargo install --path . --force
```

Minimum required Rust version: 1.70+.

## OpenCode not using RTK

```bash
rtk-tx init --global --opencode
# restart OpenCode
rtk-tx init --show    # should show "OpenCode: plugin installed"
```

## Registry or upstream install commands install the wrong package

If another package is published under a similar name, registry-based installs may install the wrong one for this fork.

Use the local rtk-tx fork checkout instead:

```bash
cargo install --path . --force
```

## Run the diagnostic script

From the RTK repository root:

```bash
bash scripts/check-installation.sh
```

Checks:
- RTK installed and in PATH
- Correct version (Token Killer, not Type Kit)
- Available features
- Claude Code integration
- Hook status

## Still stuck?

Open an issue: https://github.com/rtk-ai/rtk/issues
