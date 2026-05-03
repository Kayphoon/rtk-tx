# rtk-tx Installation Guide - For AI Coding Assistants

## ⚠️ Name Collision Warning

**There are TWO completely different projects named "rtk":**

1. ✅ **rtk-tx / Rust Token Killer fork** (this project) - LLM token optimizer
   - Repos: `rtk-ai/rtk`
   - Has `rtk-tx gain` command for token savings stats

2. ❌ **Rust Type Kit** (reachingforthejack/rtk) - DIFFERENT PROJECT
   - Rust codebase query tool and type generator
   - **DO NOT install if you want token optimization**

## Pre-Installation Check (REQUIRED)

**AI assistants should ALWAYS verify if rtk-tx is already installed before attempting installation.**

```bash
# Check if RTK is installed
rtk-tx --version

# CRITICAL: Verify it's the Token Killer (not Type Kit)
rtk-tx gain    # Should show token savings stats, NOT "command not found"

# Check installation path
which rtk-tx
```

If `rtk-tx gain` works, you have the **correct** rtk-tx installed. **DO NOT reinstall**. Skip to "Project Initialization".

If `rtk-tx gain` fails but `rtk-tx --version` succeeds, you have the **wrong** RTK (Type Kit). Uninstall and reinstall the correct one (see below).

## Installation (only if rtk-tx not available or wrong rtk installed)

### Step 0: Uninstall Wrong rtk (if needed)

If you accidentally installed Rust Type Kit:

```bash
cargo uninstall rtk-tx
```

### Source/local installation

```bash
# From this rtk-tx fork checkout (NOT reachingforthejack/rtk!)
cargo install --path .

# ALWAYS VERIFY after installation
rtk-tx gain  # MUST show token savings, not "command not found"
```

This guide uses source/local install wording until package-manager or release publishing for `rtk-tx` is available in your environment. Avoid `cargo install rtk`; that name can refer to the unrelated Rust Type Kit.

## Project Initialization

### Which mode to choose?

```
  Do you want RTK active across ALL Claude Code projects?
  │
  ├─ YES → rtk-tx init -g              (recommended)
  │         Hook + RTK.md (~10 tokens in context)
  │         Commands auto-rewritten transparently
  │
  ├─ YES, minimal → rtk-tx init -g --hook-only
  │         Hook only, nothing added to CLAUDE.md
  │         Zero tokens in context
  │
  └─ NO, single project → rtk-tx init
            Local CLAUDE.md only (137 lines)
            No hook, no global effect
```

For CodeBuddy Code, choose the CodeBuddy-specific settings target instead:

```bash
rtk-tx init --codebuddy       # project: <project-root>/.codebuddy/settings.json
rtk-tx init -g --codebuddy    # global: ~/.codebuddy/settings.json
rtk-tx hook codebuddy         # native hook adapter used in CodeBuddy settings
```

`rtk-tx` v1 does **not** patch `.codebuddy/settings.local.json`.

### Recommended: Global Hook-First Setup

**Best for: All projects, automatic RTK usage**

```bash
rtk-tx init -g
# → Installs hook to ~/.claude/hooks/rtk-rewrite.sh
# → Creates ~/.claude/RTK.md (10 lines, meta commands only)
# → Adds @RTK.md reference to ~/.claude/CLAUDE.md
# → Prompts: "Patch settings.json? [y/N]"
# → If yes: patches + creates backup (~/.claude/settings.json.bak)

# Automated alternatives:
rtk-tx init -g --auto-patch    # Patch without prompting
rtk-tx init -g --no-patch      # Print manual instructions instead

# Verify installation
rtk-tx init --show  # Check hook is installed and executable
```

**Token savings**: ~99.5% reduction (2000 tokens → 10 tokens in context)

**What is settings.json?**
Claude Code's hook registry. RTK adds a PreToolUse hook that rewrites commands transparently. Without this, Claude won't invoke the hook automatically.

**CodeBuddy settings:**
CodeBuddy uses Claude-compatible Code hooks. `rtk-tx init --codebuddy` patches `<project-root>/.codebuddy/settings.json`; `rtk-tx init -g --codebuddy` patches `~/.codebuddy/settings.json`. The inserted entry uses `hooks.PreToolUse`, matcher `Bash`, and command `rtk-tx hook codebuddy`. Rewrites are returned with `hookSpecificOutput.updatedInput.command`; for example, `rtk-tx rewrite "git status"` returns `rtk-tx git status`.

After external settings changes, CodeBuddy may require users to review or approve the hook configuration in CodeBuddy's `/hooks` panel before the hook runs.

```
  Claude Code          settings.json        rtk-rewrite.sh        rtk-tx binary
       │                    │                     │                    │
       │  "git status"      │                     │                    │
       │ ──────────────────►│                     │                    │
       │                    │  PreToolUse trigger  │                    │
       │                    │ ───────────────────►│                    │
       │                    │                     │  rewrite command   │
       │                    │                     │  → rtk-tx git status  │
       │                    │◄────────────────────│                    │
       │                    │  updated command     │                    │
       │                    │                                          │
       │  execute: rtk-tx git status                                      │
       │ ─────────────────────────────────────────────────────────────►│
       │                                                               │  filter
       │  "3 modified, 1 untracked ✓"                                  │
       │◄──────────────────────────────────────────────────────────────│
```

**Backup Safety**:
RTK backs up existing settings.json before changes. Restore if needed:
```bash
cp ~/.claude/settings.json.bak ~/.claude/settings.json
```

### Alternative: Local Project Setup

**Best for: Single project without hook**

```bash
cd /path/to/your/project
rtk-tx init  # Creates ./CLAUDE.md with full RTK instructions (137 lines)
```

**Token savings**: Instructions loaded only for this project

### Upgrading from Previous Version

#### From old 137-line CLAUDE.md injection (pre-0.22)

```bash
rtk-tx init -g  # Automatically migrates to hook-first mode
# → Removes old 137-line block
# → Installs hook + RTK.md
# → Adds @RTK.md reference
```

#### From old hook with inline logic (pre-0.24) — ⚠️ Breaking Change

rtk-tx 0.24.0 replaced the inline command-detection hook (~200 lines) with a **thin delegator** that calls `rtk-tx rewrite`. The binary now contains the rewrite logic, so adding new commands no longer requires a hook update.

The old hook still works but won't benefit from new rules added in future releases.

```bash
# Upgrade hook to thin delegator
rtk-tx init --global

# Verify the new hook is active
rtk-tx init --show
# Should show: ✅ Hook: ... (thin delegator, up to date)
```

## Common User Flows

### First-Time User (Recommended)
```bash
# 1. Install rtk-tx
cargo install --path .
rtk-tx gain  # Verify (must show token stats)

# 2. Setup with prompts
rtk-tx init -g
# → Answer 'y' when prompted to patch settings.json
# → Creates backup automatically

# 3. Restart Claude Code
# 4. Test: git status (should use rtk-tx)
```

### CodeBuddy Code User
```bash
# Project-scoped setup
rtk-tx init --codebuddy

# Or global setup for all CodeBuddy projects
rtk-tx init -g --codebuddy

# Verify rewrite behavior directly
rtk-tx rewrite "git status"  # -> rtk-tx git status

# If CodeBuddy flags the changed settings, review/approve them in /hooks.
```

### CI/CD or Automation
```bash
# Non-interactive setup (no prompts)
rtk-tx init -g --auto-patch

# Verify in scripts
rtk-tx init --show | grep "Hook:"
```

### Conservative User (Manual Control)
```bash
# Get manual instructions without patching
rtk-tx init -g --no-patch

# Review printed JSON snippet
# Manually edit ~/.claude/settings.json
# Restart Claude Code
```

### Temporary Trial
```bash
# Install hook
rtk-tx init -g --auto-patch

# Later: remove everything
rtk-tx init -g --uninstall

# Restore backup if needed
cp ~/.claude/settings.json.bak ~/.claude/settings.json
```

## Installation Verification

```bash
# Basic test
rtk-tx ls .

# Test with git
rtk-tx git status

# Test with pnpm
rtk-tx pnpm list

# Test with Vitest
rtk-tx vitest
```

## Uninstalling

### Complete Removal (Global Installations Only)

```bash
# Complete removal (global installations only)
rtk-tx init -g --uninstall

# What gets removed:
#   - Hook: ~/.claude/hooks/rtk-rewrite.sh
#   - Context: ~/.claude/RTK.md
#   - Reference: @RTK.md line from ~/.claude/CLAUDE.md
#   - Registration: RTK hook entry from settings.json

# Restart Claude Code after uninstall
```

**For Local Projects**: Manually remove RTK block from `./CLAUDE.md`

### Binary Removal

```bash
# If installed via cargo
cargo uninstall rtk-tx

# If installed via another package manager in your environment, use that manager's uninstall command.
```

### Restore from Backup (if needed)

```bash
cp ~/.claude/settings.json.bak ~/.claude/settings.json
```

## Essential Commands

### Files
```bash
rtk-tx ls .              # Compact tree view
rtk-tx read file.rs      # Optimized reading
rtk-tx grep "pattern" .  # Grouped search results
```

### Git
```bash
rtk-tx git status        # Compact status
rtk-tx git log -n 10     # Condensed logs
rtk-tx git diff          # Optimized diff
rtk-tx git add .         # → "ok ✓"
rtk-tx git commit -m "msg"  # → "ok ✓ abc1234"
rtk-tx git push          # → "ok ✓ main"
```

### Pnpm (fork only)
```bash
rtk-tx pnpm list         # Dependency tree (-70% tokens)
rtk-tx pnpm outdated     # Available updates (-80-90%)
rtk-tx pnpm install pkg  # Silent installation
```

### Tests
```bash
rtk-tx cargo test      # Filtered Cargo test output (-90%)
rtk-tx go test         # Filtered Go tests (NDJSON, -90%)
rtk-tx jest            # Filtered Jest output (-99.6%)
rtk-tx vitest          # Filtered Vitest output (-99.6%)
rtk-tx playwright test # Filtered Playwright output (-94%)
rtk-tx pytest          # Filtered Python tests (-90%)
rtk-tx rake test       # Filtered Ruby tests (-90%)
rtk-tx rspec           # Filtered RSpec tests (-60%)
rtk-tx test <cmd>      # Generic test wrapper - failures only (-90%)
```

### Statistics
```bash
rtk-tx gain              # Token savings
rtk-tx gain --graph      # With ASCII graph
rtk-tx gain --history    # With command history
```

## Validated Token Savings

### Production T3 Stack Project
| Operation | Standard | RTK | Reduction |
|-----------|----------|-----|-----------|
| `vitest` | 102,199 chars | 377 chars | **-99.6%** |
| `git status` | 529 chars | 217 chars | **-59%** |
| `pnpm list` | ~8,000 tokens | ~2,400 | **-70%** |
| `pnpm outdated` | ~12,000 tokens | ~1,200-2,400 | **-80-90%** |

### Typical Claude Code Session (30 min)
- **Without RTK**: ~150,000 tokens
- **With RTK**: ~45,000 tokens
- **Savings**: **70% reduction**

## Troubleshooting

### rtk-tx command not found after installation
```bash
# Check PATH
echo $PATH | grep -o '[^:]*\.cargo[^:]*'

# Add to PATH if needed (~/.bashrc or ~/.zshrc)
export PATH="$HOME/.cargo/bin:$PATH"

# Reload shell
source ~/.bashrc  # or source ~/.zshrc
```

### rtk-tx command not available (e.g., vitest)
Rebuild and reinstall from the current `rtk-tx` fork checkout:

```bash
cargo install --path . --force
rtk-tx --help
```

### Compilation error
```bash
# Update Rust
rustup update stable

# Clean and recompile
cargo clean
cargo build --release
cargo install --path . --force
```

## Support and Contributing

- **Website**: https://www.rtk-ai.app
- **Contact**: contact@rtk-ai.app
- **Troubleshooting**: See [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) for common issues
- **GitHub issues**: https://github.com/rtk-ai/rtk/issues
- **Pull Requests**: https://github.com/rtk-ai/rtk/pulls

⚠️ **If you installed the wrong rtk (Type Kit)**, see [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md#problem-rtk-gain-command-not-found)

## AI Assistant Checklist

Before each session:

- [ ] Verify RTK is installed: `rtk-tx --version`
- [ ] If not installed → follow "Install from fork"
- [ ] If project not initialized → `rtk-tx init`
- [ ] Use `rtk-tx` for ALL git/pnpm/test/vitest commands
- [ ] Check savings: `rtk-tx gain`

**Golden Rule**: AI coding assistants should ALWAYS use `rtk-tx` as a proxy for shell commands that generate verbose output (git, pnpm, npm, cargo test, vitest, docker, kubectl).
