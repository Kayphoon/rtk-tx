"""Hermes plugin adapter for RTK command rewriting.

All rewrite logic lives in RTK's Rust ``rtk rewrite`` command; this module
only bridges Hermes ``pre_tool_call`` payloads to that command and fails open.
"""

import subprocess


ACCEPTED_REWRITE_RETURN_CODES = {0, 3}


def register(ctx):
    """Register the Hermes pre-tool callback."""
    ctx.register_hook("pre_tool_call", _pre_tool_call)


def _pre_tool_call(tool_name=None, args=None, **_kwargs):
    """Rewrite mutable Hermes terminal command args when RTK provides a change."""
    try:
        if tool_name != "terminal" or not isinstance(args, dict):
            return

        command = args.get("command")
        if not isinstance(command, str) or not command.strip():
            return

        result = subprocess.run(
            ["rtk", "rewrite", command],
            shell=False,
            timeout=2,
            capture_output=True,
            text=True,
        )

        if result.returncode not in ACCEPTED_REWRITE_RETURN_CODES:
            return

        rewritten = result.stdout.strip()
        if rewritten and rewritten != command:
            args["command"] = rewritten
    except Exception:
        return
