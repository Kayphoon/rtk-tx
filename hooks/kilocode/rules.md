# RTK - Rust Token Killer (Kilo Code)

**Usage**: Token-optimized CLI proxy for shell commands.

## Rule

Always prefix shell commands with `rtk-tx` to minimize token consumption.

Examples:

```bash
rtk-tx git status
rtk-tx cargo test
rtk-tx ls src/
rtk-tx grep "pattern" src/
rtk-tx find "*.rs" .
rtk-tx docker ps
rtk-tx gh pr list
```

## Meta Commands

```bash
rtk-tx gain              # Show token savings
rtk-tx gain --history    # Command history with savings
rtk-tx discover          # Find missed RTK opportunities
rtk-tx proxy <cmd>       # Run raw (no filtering, for debugging)
```

## Why

RTK filters and compresses command output before it reaches the LLM context, saving 60-90% tokens on common operations. Always use `rtk-tx <cmd>` instead of raw commands.
