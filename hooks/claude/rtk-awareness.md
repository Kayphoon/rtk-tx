# RTK - Rust Token Killer

**Usage**: Token-optimized CLI proxy (60-90% savings on dev operations)

## Meta Commands (always use rtk-tx directly)

```bash
rtk-tx gain              # Show token savings analytics
rtk-tx gain --history    # Show command usage history with savings
rtk-tx discover          # Analyze Claude Code history for missed opportunities
rtk-tx proxy <cmd>       # Execute raw command without filtering (for debugging)
```

## Installation Verification

```bash
rtk-tx --version      # Should show: rtk-tx X.Y.Z
rtk-tx gain           # Should work (not "command not found")
which rtk-tx          # Verify correct binary
```

⚠️ **Name collision**: If `rtk-tx gain` fails, you may have the wrong RTK installed or `rtk-tx` is missing.

## Hook-Based Usage

All other commands are automatically rewritten by the Claude Code hook.
Example: `git status` → `rtk-tx git status` (transparent, 0 tokens overhead)

Refer to CLAUDE.md for full command reference.
