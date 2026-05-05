# Telemetry & Local Tracking

rtk-tx v1 does **not** send remote telemetry. The startup hook `core::telemetry::maybe_ping()` is a no-op, no telemetry endpoint is compiled or called, and `rtk-tx telemetry forget` does not contact a server.

Local SQLite tracking remains enabled by default so `rtk-tx gain`, `rtk-tx discover`, and related analytics can show token savings on your own machine.

## What stays local

- Command history and token-savings metrics are stored in SQLite.
- Default database path: `~/.local/share/rtk-tx/history.db` on Linux/macOS-style local-data directories.
- Retention defaults to 90 days and is controlled by `[tracking].history_days` in `config.toml`.
- The local device salt used by `rtk-tx telemetry status` is stored under the `rtk-tx` local data directory.

## What is not sent

rtk-tx v1 sends no telemetry payloads, including:

- source code or file contents
- command lines, arguments, or paths
- secrets, environment variables, or repository data
- usage metrics, device hashes, OS/version data, or erasure requests

## Commands

```bash
rtk-tx telemetry status     # Show local telemetry/tracking status
rtk-tx telemetry enable     # No-op for remote telemetry; keeps remote sending disabled
rtk-tx telemetry disable    # Save disabled consent state locally
rtk-tx telemetry forget     # Delete local salt/marker/tracking DB; no server request
```

`RTK_TELEMETRY_DISABLED=1` is still accepted as a harmless explicit block, but remote telemetry is disabled regardless of this variable.

## Tracking database path

Override the local tracking database path with:

```bash
export RTK_TX_DB_PATH=/custom/path/history.db
```

If `RTK_TX_DB_PATH` is unset, rtk-tx uses `[tracking].database_path` from config, then the default `rtk-tx/history.db` path.

## Erasure / deletion

`rtk-tx telemetry forget`:

1. records telemetry as disabled in local config,
2. deletes the local device salt and telemetry marker if present,
3. deletes the local SQLite tracking database resolved through `RTK_TX_DB_PATH`, config, or the default `rtk-tx/history.db` path,
4. prints that remote telemetry is absent and no server-side erasure request was sent or needed.

You can also delete `~/.local/share/rtk-tx/history.db` manually; it will be recreated on the next tracked command.

## Contributor notes

- Do not add remote telemetry/network sending for v1.
- Keep `core::telemetry::maybe_ping()` free of network I/O regardless of build environment variables.
- Keep local tracking/gain functionality independent from remote telemetry.
