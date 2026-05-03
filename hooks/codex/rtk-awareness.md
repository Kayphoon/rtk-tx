# RTK - Rust Token Killer (Codex CLI)

**Usage**: Token-optimized CLI proxy for shell commands.

## Rule

Always prefix shell commands with `rtk-tx`.

Examples:

```bash
rtk-tx git status
rtk-tx cargo test
rtk-tx npm run build
rtk-tx pytest -q
```

## Meta Commands

```bash
rtk-tx gain            # Token savings analytics
rtk-tx gain --history  # Recent command savings history
rtk-tx proxy <cmd>     # Run raw command without filtering
```

## Verification

```bash
rtk-tx --version
rtk-tx gain
which rtk-tx
```
