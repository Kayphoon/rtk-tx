pub const REWRITE_HOOK_FILE: &str = "rtk-rewrite.sh";
pub const GEMINI_HOOK_FILE: &str = "rtk-hook-gemini.sh";
pub const CLAUDE_DIR: &str = ".claude";
pub const CODEBUDDY_DIR: &str = ".codebuddy";
pub const WORKBUDDY_DIR: &str = ".workbuddy";
pub const HOOKS_SUBDIR: &str = "hooks";
pub const SETTINGS_JSON: &str = "settings.json";
pub const SETTINGS_LOCAL_JSON: &str = "settings.local.json";
pub const HOOKS_JSON: &str = "hooks.json";
pub const PRE_TOOL_USE_KEY: &str = "PreToolUse";
pub const BEFORE_TOOL_KEY: &str = "BeforeTool";

/// Native Rust hook command for Claude Code (replaces rtk-rewrite.sh).
pub const CLAUDE_HOOK_COMMAND: &str = "rtk hook claude";
/// Native Rust hook command for Cursor (replaces rtk-rewrite.sh).
pub const CURSOR_HOOK_COMMAND: &str = "rtk hook cursor";
/// Native Rust hook command for CodeBuddy Code.
pub const CODEBUDDY_HOOK_COMMAND: &str = "rtk-tx hook codebuddy";
/// Native Rust hook command for WorkBuddy.
pub const WORKBUDDY_HOOK_COMMAND: &str = "rtk-tx hook workbuddy";

pub const OPENCODE_PLUGIN_PATH: &str = ".config/opencode/plugins/rtk.ts";
pub const CURSOR_DIR: &str = ".cursor";
pub const CODEX_DIR: &str = ".codex";
pub const GEMINI_DIR: &str = ".gemini";

// ── CodeBuddy plugin constants ───────────────────────────────

/// Plugin name used in the marketplace directory and plugin.json.
pub const CODEBUDDY_PLUGIN_NAME: &str = "rtk-tx";
/// Marketplace name where the plugin is installed.
pub const CODEBUDDY_PLUGIN_MARKETPLACE: &str = "codebuddy-plugins-official";
/// Key used in `enabledPlugins` in settings.json to enable the plugin.
pub const CODEBUDDY_PLUGIN_ENABLED_KEY: &str = "rtk-tx@codebuddy-plugins-official";
/// Subdirectory inside the plugin dir that holds the manifest.
pub const CODEBUDDY_PLUGIN_MANIFEST_DIR: &str = ".codebuddy-plugin";
/// Manifest file name inside the manifest subdirectory.
pub const CODEBUDDY_PLUGIN_MANIFEST_FILE: &str = "plugin.json";
