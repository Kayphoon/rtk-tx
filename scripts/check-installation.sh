#!/usr/bin/env bash
# rtk-tx Installation Verification Script
# Helps diagnose if you have the correct rtk-tx (Token Killer) installed

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "═══════════════════════════════════════════════════════════"
echo "           rtk-tx Installation Verification"
echo "═══════════════════════════════════════════════════════════"
echo ""

# Check 1: rtk-tx installed?
echo "1. Checking if rtk-tx is installed..."
if command -v rtk-tx &> /dev/null; then
    echo -e "   ${GREEN}✅ rtk-tx is installed${NC}"
    RTK_PATH=$(which rtk-tx)
    echo "   Location: $RTK_PATH"
else
    echo -e "   ${RED}❌ rtk-tx is NOT installed${NC}"
    echo ""
    echo "   Install from this fork checkout with:"
    echo "   cargo install --path ."
    exit 1
fi
echo ""

# Check 2: rtk-tx version
echo "2. Checking rtk-tx version..."
RTK_VERSION=$(rtk-tx --version 2>/dev/null || echo "unknown")
echo "   Version: $RTK_VERSION"
echo ""

# Check 3: Is it Token Killer or Type Kit?
echo "3. Verifying this is Token Killer (not Type Kit)..."
if rtk-tx gain &>/dev/null || rtk-tx gain --help &>/dev/null; then
    echo -e "   ${GREEN}✅ CORRECT - You have Rust Token Killer${NC}"
    CORRECT_RTK=true
else
    echo -e "   ${RED}❌ WRONG - You have Rust Type Kit (different project!)${NC}"
    echo ""
    echo "   You installed the wrong package. Fix it with:"
    echo "   cargo uninstall rtk-tx"
    echo "   cargo install --path ."
    CORRECT_RTK=false
fi
echo ""

if [ "$CORRECT_RTK" = false ]; then
    echo "═══════════════════════════════════════════════════════════"
    echo -e "${RED}INSTALLATION CHECK FAILED${NC}"
    echo "═══════════════════════════════════════════════════════════"
    exit 1
fi

# Check 4: Available features
echo "4. Checking available features..."
FEATURES=()
MISSING_FEATURES=()

check_command() {
    local cmd=$1
    local name=$2
    if rtk-tx --help 2>/dev/null | grep -qw "$cmd"; then
        echo -e "   ${GREEN}✅${NC} $name"
        FEATURES+=("$name")
    else
        echo -e "   ${YELLOW}⚠️${NC}  $name (missing - upgrade to fork?)"
        MISSING_FEATURES+=("$name")
    fi
}

check_command "gain" "Token savings analytics"
check_command "git" "Git operations"
check_command "gh" "GitHub CLI"
check_command "pnpm" "pnpm support"
check_command "vitest" "Vitest test runner"
check_command "lint" "ESLint/linters"
check_command "tsc" "TypeScript compiler"
check_command "next" "Next.js"
check_command "prettier" "Prettier"
check_command "playwright" "Playwright E2E"
check_command "prisma" "Prisma ORM"
check_command "discover" "Discover missed savings"

echo ""

# Check 5: CLAUDE.md initialization
echo "5. Checking Claude Code integration..."
GLOBAL_INIT=false
LOCAL_INIT=false

if [ -f "$HOME/.claude/CLAUDE.md" ] && grep -q "rtk" "$HOME/.claude/CLAUDE.md"; then
    echo -e "   ${GREEN}✅${NC} Global CLAUDE.md initialized (~/.claude/CLAUDE.md)"
    GLOBAL_INIT=true
else
    echo -e "   ${YELLOW}⚠️${NC}  Global CLAUDE.md not initialized"
    echo "      Run: rtk-tx init --global"
fi

if [ -f "./CLAUDE.md" ] && grep -q "rtk" "./CLAUDE.md"; then
    echo -e "   ${GREEN}✅${NC} Local CLAUDE.md initialized (./CLAUDE.md)"
    LOCAL_INIT=true
else
    echo -e "   ${YELLOW}⚠️${NC}  Local CLAUDE.md not initialized in current directory"
    echo "      Run: rtk-tx init (in your project directory)"
fi
echo ""

# Check 6: CodeBuddy integration
echo "6. Checking CodeBuddy integration..."
CODEBUDDY_INIT=false
if [ -f "./.codebuddy/settings.json" ] && grep -q "rtk-tx hook codebuddy" "./.codebuddy/settings.json"; then
    echo -e "   ${GREEN}✅${NC} Project CodeBuddy settings initialized (./.codebuddy/settings.json)"
    CODEBUDDY_INIT=true
elif [ -f "$HOME/.codebuddy/settings.json" ] && grep -q "rtk-tx hook codebuddy" "$HOME/.codebuddy/settings.json"; then
    echo -e "   ${GREEN}✅${NC} Global CodeBuddy settings initialized (~/.codebuddy/settings.json)"
    CODEBUDDY_INIT=true
else
    echo -e "   ${YELLOW}⚠️${NC}  CodeBuddy settings not initialized"
    echo "      Run: rtk-tx init --codebuddy (project)"
    echo "      Or:  rtk-tx init -g --codebuddy (global)"
    echo "      Note: .codebuddy/settings.local.json is not patched by rtk-tx v1"
fi
echo "      If CodeBuddy reports externally changed hooks, review/approve them in /hooks."
echo ""

# Check 6b: WorkBuddy integration
echo "6b. Checking WorkBuddy integration..."
WORKBUDDY_INIT=false
if [ -f "./.workbuddy/settings.json" ] && grep -q "rtk-tx hook workbuddy" "./.workbuddy/settings.json"; then
    echo -e "   ${GREEN}✅${NC} Project WorkBuddy settings initialized (./.workbuddy/settings.json)"
    WORKBUDDY_INIT=true
elif [ -f "$HOME/.workbuddy/settings.json" ] && grep -q "rtk-tx hook workbuddy" "$HOME/.workbuddy/settings.json"; then
    echo -e "   ${GREEN}✅${NC} Global WorkBuddy settings initialized (~/.workbuddy/settings.json)"
    WORKBUDDY_INIT=true
else
    echo -e "   ${YELLOW}⚠️${NC}  WorkBuddy settings not initialized"
    echo "      Run: rtk-tx init --workbuddy (project)"
    echo "      Or:  rtk-tx init -g --workbuddy (global)"
    echo "      Note: .workbuddy/settings.local.json is not patched by rtk-tx v1"
fi
echo ""

# Check 7: Auto-rewrite hook
echo "7. Checking auto-rewrite hook (optional but recommended)..."
if [ -f "$HOME/.claude/hooks/rtk-rewrite.sh" ]; then
    echo -e "   ${GREEN}✅${NC} Hook script installed"
    if [ -f "$HOME/.claude/settings.json" ] && grep -q "rtk-rewrite.sh" "$HOME/.claude/settings.json"; then
        echo -e "   ${GREEN}✅${NC} Hook enabled in settings.json"
    else
        echo -e "   ${YELLOW}⚠️${NC}  Hook script exists but not enabled in settings.json"
        echo "      See README.md 'Auto-Rewrite Hook' section"
    fi
else
    echo -e "   ${YELLOW}⚠️${NC}  Auto-rewrite hook not installed (optional)"
    echo "      Install: cp .claude/hooks/rtk-rewrite.sh ~/.claude/hooks/"
fi
echo ""

# Summary
echo "═══════════════════════════════════════════════════════════"
echo "                    SUMMARY"
echo "═══════════════════════════════════════════════════════════"

if [ ${#MISSING_FEATURES[@]} -gt 0 ]; then
    echo -e "${YELLOW}⚠️  You have a basic RTK installation${NC}"
    echo ""
    echo "Missing features:"
    for feature in "${MISSING_FEATURES[@]}"; do
        echo "  - $feature"
    done
    echo ""
    echo "To get all features, install the fork from this checkout:"
    echo "  cargo uninstall rtk-tx"
    echo "  cargo install --path . --force"
else
    echo -e "${GREEN}✅ Full-featured rtk-tx installation detected${NC}"
fi

echo ""

if [ "$GLOBAL_INIT" = false ] && [ "$LOCAL_INIT" = false ]; then
    echo -e "${YELLOW}⚠️  rtk-tx not initialized for Claude Code${NC}"
    echo "   Run: rtk-tx init --global (for all projects)"
    echo "   Or:  rtk-tx init (for this project only)"
fi

if [ "$CODEBUDDY_INIT" = false ]; then
    echo -e "${YELLOW}ℹ️  CodeBuddy setup is optional${NC}"
    echo "   Run: rtk-tx init --codebuddy or rtk-tx init -g --codebuddy"
fi

if [ "$WORKBUDDY_INIT" = false ]; then
    echo -e "${YELLOW}ℹ️  WorkBuddy setup is optional${NC}"
    echo "   Run: rtk-tx init --workbuddy or rtk-tx init -g --workbuddy"
fi

echo ""
echo "Need help? See docs/TROUBLESHOOTING.md"
echo "═══════════════════════════════════════════════════════════"
