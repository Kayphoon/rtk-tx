---
title: Telemetry & Privacy
description: Remote telemetry is disabled in rtk-tx v1; local tracking stays on-device
sidebar:
  order: 3
---

# Telemetry & Privacy

rtk-tx v1 does **not** send remote telemetry. No daily ping is sent, no telemetry endpoint is compiled or called, and `rtk-tx telemetry forget` does not contact a server.

Local SQLite tracking remains available for `rtk-tx gain` analytics.

## Local data

- Default tracking DB: `~/.local/share/rtk-tx/history.db`
- Config file: `~/.config/rtk-tx/config.toml` on Linux-style config directories
- Retention: 90 days by default via `[tracking].history_days`
- Custom DB path: `RTK_TX_DB_PATH=/custom/path/history.db`

If `RTK_TX_DB_PATH` is unset, rtk-tx uses `[tracking].database_path` from config, then the default location above.

## What is not sent

rtk-tx v1 sends no remote telemetry payloads or erasure requests. It does not send source code, file paths, command arguments, usage metrics, device hashes, environment details, secrets, or repository data.

## Commands

```bash
rtk-tx telemetry status     # Show local status
rtk-tx telemetry enable     # Remote telemetry remains disabled/absent
rtk-tx telemetry disable    # Save disabled state locally
rtk-tx telemetry forget     # Delete local salt/marker/tracking DB only
```

`RTK_TELEMETRY_DISABLED=1` remains a harmless explicit block, but remote telemetry is disabled regardless.

## Delete local data

Run:

```bash
rtk-tx telemetry forget
```

This deletes local telemetry identity files and the local tracking database resolved through `RTK_TX_DB_PATH`, config, or the default `rtk-tx/history.db` location. No server-side erasure request is sent or needed because remote telemetry is absent in this v1 fork.
