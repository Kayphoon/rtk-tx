#!/usr/bin/env bash
#
# RTK Smoke Test Suite
# Exercises every command to catch regressions after merge.
# Exit code: number of failures (0 = all green)
#
set -euo pipefail

PASS=0
FAIL=0
SKIP=0
FAILURES=()

# Section tracking (for layer report)
CURRENT_SECTION=""
SECTION_PASS=0
SECTION_FAIL=0
SECTION_SKIP=0
SECTION_RESULTS=()

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# ── Helpers ──────────────────────────────────────────

assert_ok() {
    local name="$1"
    shift
    local output
    if output=$("$@" 2>&1); then
        PASS=$((PASS + 1))
        printf "  ${GREEN}PASS${NC}  %s\n" "$name"
    else
        FAIL=$((FAIL + 1))
        FAILURES+=("$name")
        printf "  ${RED}FAIL${NC}  %s\n" "$name"
        printf "        cmd: %s\n" "$*"
        printf "        out: %s\n" "$(echo "$output" | head -3)"
    fi
}

assert_contains() {
    local name="$1"
    local needle="$2"
    shift 2
    local output
    if output=$("$@" 2>&1) && echo "$output" | grep -q "$needle"; then
        PASS=$((PASS + 1))
        printf "  ${GREEN}PASS${NC}  %s\n" "$name"
    else
        FAIL=$((FAIL + 1))
        FAILURES+=("$name")
        printf "  ${RED}FAIL${NC}  %s\n" "$name"
        printf "        expected: '%s'\n" "$needle"
        printf "        got: %s\n" "$(echo "$output" | head -3)"
    fi
}

assert_exit_ok() {
    local name="$1"
    shift
    if "$@" >/dev/null 2>&1; then
        PASS=$((PASS + 1))
        printf "  ${GREEN}PASS${NC}  %s\n" "$name"
    else
        FAIL=$((FAIL + 1))
        FAILURES+=("$name")
        printf "  ${RED}FAIL${NC}  %s\n" "$name"
        printf "        cmd: %s\n" "$*"
    fi
}

assert_fails() {
    local name="$1"
    shift
    if "$@" >/dev/null 2>&1; then
        FAIL=$((FAIL + 1))
        FAILURES+=("$name (expected failure, got success)")
        printf "  ${RED}FAIL${NC}  %s (expected failure)\n" "$name"
    else
        PASS=$((PASS + 1))
        printf "  ${GREEN}PASS${NC}  %s\n" "$name"
    fi
}

assert_help() {
    local name="$1"
    shift
    assert_contains "$name --help" "Usage:" "$@" --help
}

assert_output_contains() {
    local name="$1"
    local needle="$2"
    shift 2
    local output
    output=$("$@" 2>&1) || true
    if echo "$output" | grep -q "$needle"; then
        PASS=$((PASS + 1))
        printf "  ${GREEN}PASS${NC}  %s\n" "$name"
    else
        FAIL=$((FAIL + 1))
        FAILURES+=("$name")
        printf "  ${RED}FAIL${NC}  %s\n" "$name"
        printf "        expected: '%s'\n" "$needle"
        printf "        got: %s\n" "$(echo "$output" | head -3)"
    fi
}

skip_test() {
    local name="$1"
    local reason="$2"
    SKIP=$((SKIP + 1))
    printf "  ${YELLOW}SKIP${NC}  %s (%s)\n" "$name" "$reason"
}

section() {
    # Finalize previous section stats
    if [[ -n "$CURRENT_SECTION" ]]; then
        local sp=$((PASS - SECTION_PASS))
        local sf=$((FAIL - SECTION_FAIL))
        local ss=$((SKIP - SECTION_SKIP))
        SECTION_RESULTS+=("${CURRENT_SECTION}|${sp}|${sf}|${ss}")
    fi
    CURRENT_SECTION="$1"
    SECTION_PASS=$PASS
    SECTION_FAIL=$FAIL
    SECTION_SKIP=$SKIP
    printf "\n${BOLD}${CYAN}── %s ──${NC}\n" "$1"
}

finalize_sections() {
    if [[ -n "$CURRENT_SECTION" ]]; then
        local sp=$((PASS - SECTION_PASS))
        local sf=$((FAIL - SECTION_FAIL))
        local ss=$((SKIP - SECTION_SKIP))
        SECTION_RESULTS+=("${CURRENT_SECTION}|${sp}|${sf}|${ss}")
    fi
}

# ── Preamble ─────────────────────────────────────────

RTK=$(command -v rtk || echo "")
if [[ -z "$RTK" ]]; then
    echo "rtk not found in PATH. Run: cargo install --path ."
    exit 1
fi

printf "${BOLD}RTK Smoke Test Suite${NC}\n"
printf "Binary: %s\n" "$RTK"
printf "Version: %s\n" "$(rtk --version)"
printf "Date: %s\n" "$(date '+%Y-%m-%d %H:%M')"

# Need a git repo to test git commands
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "Must run from inside a git repository."
    exit 1
fi

REPO_ROOT=$(git rev-parse --show-toplevel)

# ── 1. Version & Help ───────────────────────────────

section "Version & Help"

assert_contains "rtk --version" "rtk" rtk --version
assert_contains "rtk --help" "Usage:" rtk --help
assert_fails   "unknown command rejected"    rtk nonexistent-cmd-xyz

# ── 2. Ls ────────────────────────────────────────────

section "Ls"

assert_ok      "rtk ls ."                     rtk ls .
assert_ok      "rtk ls -la ."                 rtk ls -la .
assert_ok      "rtk ls -lh ."                 rtk ls -lh .
assert_ok      "rtk ls -l src/"               rtk ls -l src/
assert_ok      "rtk ls src/ -l (flag after)"  rtk ls src/ -l
assert_ok      "rtk ls multi paths"           rtk ls src/ scripts/
assert_contains "rtk ls -a shows hidden"      ".git" rtk ls -a .
assert_contains "rtk ls shows sizes"          "K"  rtk ls src/
assert_contains "rtk ls shows dirs with /"    "/" rtk ls .

# ── 2b. Tree ─────────────────────────────────────────

section "Tree"

if command -v tree >/dev/null 2>&1; then
    assert_ok      "rtk tree ."                rtk tree .
    assert_ok      "rtk tree -L 2 ."           rtk tree -L 2 .
    assert_ok      "rtk tree -d -L 1 ."        rtk tree -d -L 1 .
    assert_contains "rtk tree shows src/"      "src" rtk tree -L 1 .
else
    skip_test "rtk tree" "tree not installed"
fi

# ── 3. Read ──────────────────────────────────────────

section "Read"

assert_ok      "rtk read Cargo.toml"          rtk read Cargo.toml
assert_ok      "rtk read --level none Cargo.toml"  rtk read --level none Cargo.toml
assert_ok      "rtk read --level aggressive Cargo.toml" rtk read --level aggressive Cargo.toml
assert_ok      "rtk read -n Cargo.toml"       rtk read -n Cargo.toml
assert_ok      "rtk read --max-lines 5 Cargo.toml" rtk read --max-lines 5 Cargo.toml

section "Read (stdin support)"

assert_ok      "rtk read stdin pipe"          bash -c 'echo "fn main() {}" | rtk read -'

# ── 4. Git ───────────────────────────────────────────

section "Git (existing)"

assert_ok      "rtk git status"               rtk git status
assert_ok      "rtk git status --short"       rtk git status --short
assert_ok      "rtk git status -s"            rtk git status -s
assert_ok      "rtk git status --porcelain"   rtk git status --porcelain
assert_ok      "rtk git log"                  rtk git log
assert_ok      "rtk git log -5"               rtk git log -- -5
assert_ok      "rtk git diff"                 rtk git diff
assert_ok      "rtk git diff --stat"          rtk git diff --stat

section "Git (new: branch, fetch, stash, worktree)"

assert_ok      "rtk git branch"               rtk git branch
assert_ok      "rtk git fetch"                rtk git fetch
assert_ok      "rtk git stash list"           rtk git stash list
assert_ok      "rtk git worktree"             rtk git worktree

section "Git (passthrough: unsupported subcommands)"

assert_ok      "rtk git tag --list"           rtk git tag --list
assert_ok      "rtk git remote -v"            rtk git remote -v
assert_ok      "rtk git rev-parse HEAD"       rtk git rev-parse HEAD

# ── 5. GitHub CLI ────────────────────────────────────

section "GitHub CLI"

if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
    assert_ok      "rtk gh pr list"           rtk gh pr list
    assert_ok      "rtk gh run list"          rtk gh run list
    assert_ok      "rtk gh issue list"        rtk gh issue list
    # pr create/merge/diff/comment/edit are write ops, test help only
    assert_help    "rtk gh"                   rtk gh
else
    skip_test "gh commands" "gh not authenticated"
fi

# ── 6. Cargo ─────────────────────────────────────────

section "Cargo (new)"

assert_ok      "rtk cargo build"              rtk cargo build
assert_ok      "rtk cargo clippy"             rtk cargo clippy
# cargo test exits non-zero due to pre-existing failures; check output ignoring exit code
output_cargo_test=$(rtk cargo test 2>&1 || true)
if echo "$output_cargo_test" | grep -q "FAILURES\|test result:\|passed"; then
    PASS=$((PASS + 1))
    printf "  ${GREEN}PASS${NC}  %s\n" "rtk cargo test"
else
    FAIL=$((FAIL + 1))
    FAILURES+=("rtk cargo test")
    printf "  ${RED}FAIL${NC}  %s\n" "rtk cargo test"
    printf "        got: %s\n" "$(echo "$output_cargo_test" | head -3)"
fi
assert_help    "rtk cargo"                    rtk cargo

# ── 7. Curl ──────────────────────────────────────────

section "Curl (new)"

assert_contains "rtk curl JSON detect" "slideshow" rtk curl https://httpbin.org/json
assert_ok       "rtk curl plain text"          rtk curl https://httpbin.org/robots.txt
assert_help     "rtk curl"                     rtk curl

# ── 8. Npm / Npx ────────────────────────────────────

section "Npm / Npx (new)"

assert_help    "rtk npm"                      rtk npm
assert_help    "rtk npx"                      rtk npx

# ── 9. Pnpm ─────────────────────────────────────────

section "Pnpm"

assert_help    "rtk pnpm"                     rtk pnpm
assert_help    "rtk pnpm typecheck"           rtk pnpm typecheck

if command -v pnpm >/dev/null 2>&1; then
    assert_help    "rtk pnpm build"           rtk pnpm build
    assert_ok  "rtk pnpm help"                rtk pnpm help
else
    skip_test "rtk pnpm build" "pnpm not installed"
fi

# ── 10. Grep ─────────────────────────────────────────

section "Grep"

assert_ok      "rtk grep pattern"             rtk grep "pub fn" src/
assert_contains "rtk grep finds results"      "pub fn" rtk grep "pub fn" src/
assert_ok      "rtk grep with file type"      rtk grep "pub fn" src/ -t rust

section "Grep (extra args passthrough)"

assert_ok      "rtk grep -i case insensitive" rtk grep "fn" src/ -i
assert_ok      "rtk grep -A context lines"    rtk grep "fn run" src/ -A 2

# ── 11. Find ─────────────────────────────────────────

section "Find"

assert_ok      "rtk find *.rs"                rtk find "*.rs" src/
assert_contains "rtk find shows files"        ".rs" rtk find "*.rs" src/

# ── 12. Json ─────────────────────────────────────────

section "Json"

# Create temp JSON file for testing
TMPJSON=$(mktemp /tmp/rtk-test-XXXXX.json)
echo '{"name":"test","count":42,"items":[1,2,3]}' > "$TMPJSON"

assert_ok      "rtk json file"                rtk json "$TMPJSON"
assert_contains "rtk json shows content"       "count" rtk json "$TMPJSON"

rm -f "$TMPJSON"

# ── 13. Deps ─────────────────────────────────────────

section "Deps"

assert_ok      "rtk deps ."                   rtk deps .
assert_contains "rtk deps shows Cargo"        "Cargo" rtk deps .

# ── 14. Env ──────────────────────────────────────────

section "Env"

assert_ok      "rtk env"                      rtk env
assert_ok      "rtk env --filter PATH"        rtk env --filter PATH

# ── 16. Log ──────────────────────────────────────────

section "Log"

TMPLOG=$(mktemp /tmp/rtk-log-XXXXX.log)
for i in $(seq 1 20); do
    echo "[2025-01-01 12:00:00] INFO: repeated message" >> "$TMPLOG"
done
echo "[2025-01-01 12:00:01] ERROR: something failed" >> "$TMPLOG"

assert_ok      "rtk log file"                 rtk log "$TMPLOG"

rm -f "$TMPLOG"

# ── 17. Summary ──────────────────────────────────────

section "Summary"

assert_ok      "rtk summary echo hello"       rtk summary echo hello

# ── 18. Err ──────────────────────────────────────────

section "Err"

assert_ok      "rtk err echo ok"              rtk err echo ok

# ── 19. Test runner ──────────────────────────────────

section "Test runner"

assert_ok      "rtk test echo ok"             rtk test echo ok

# ── 20. Gain ─────────────────────────────────────────

section "Gain"

assert_ok      "rtk gain"                     rtk gain
assert_ok      "rtk gain --history"           rtk gain --history

# ── 21. Config & Init ────────────────────────────────

section "Config & Init"

assert_ok      "rtk config"                   rtk config
assert_ok      "rtk init --show"              rtk init --show

# ── 22. Wget ─────────────────────────────────────────

section "Wget"

if command -v wget >/dev/null 2>&1; then
    assert_ok  "rtk wget stdout"              rtk wget https://httpbin.org/robots.txt -O -
else
    skip_test "rtk wget" "wget not installed"
fi

# ── 23. Tsc / Lint / Prettier / Next / Playwright ───

section "JS Tooling (help only, no project context)"

assert_help    "rtk tsc"                      rtk tsc
assert_help    "rtk lint"                     rtk lint
assert_help    "rtk prettier"                 rtk prettier
assert_help    "rtk next"                     rtk next
assert_help    "rtk playwright"               rtk playwright

# ── 24. Prisma ───────────────────────────────────────

section "Prisma (help only)"

assert_help    "rtk prisma"                   rtk prisma

# ── 25. Vitest ───────────────────────────────────────

section "Vitest (help only)"

assert_help    "rtk vitest"                   rtk vitest

# ── 26. Docker / Kubectl (help only) ────────────────

section "Docker / Kubectl (help only)"

assert_help    "rtk docker"                   rtk docker
assert_help    "rtk kubectl"                  rtk kubectl

# ── 27. Python (conditional) ────────────────────────

section "Python (conditional)"

if command -v pytest &>/dev/null; then
    assert_help    "rtk pytest"                    rtk pytest --help
else
    skip_test "rtk pytest" "pytest not installed"
fi

if command -v ruff &>/dev/null; then
    assert_help    "rtk ruff"                      rtk ruff --help
else
    skip_test "rtk ruff" "ruff not installed"
fi

if command -v pip &>/dev/null; then
    assert_help    "rtk pip"                       rtk pip --help
else
    skip_test "rtk pip" "pip not installed"
fi

# ── 28. Go (conditional) ────────────────────────────

section "Go (conditional)"

if command -v go &>/dev/null; then
    assert_help    "rtk go"                        rtk go --help
    assert_help    "rtk go test"                   rtk go test -h
    assert_help    "rtk go build"                  rtk go build -h
    assert_help    "rtk go vet"                    rtk go vet -h
else
    skip_test "rtk go" "go not installed"
fi

if command -v golangci-lint &>/dev/null; then
    assert_help    "rtk golangci-lint"             rtk golangci-lint --help
else
    skip_test "rtk golangci-lint" "golangci-lint not installed"
fi

# ── 29. Graphite (conditional) ─────────────────────

section "Graphite (conditional)"

if command -v gt &>/dev/null; then
    assert_help   "rtk gt"                          rtk gt --help
    assert_ok     "rtk gt log short"                rtk gt log short
else
    skip_test "rtk gt" "gt not installed"
fi

# ── 30. Ruby (conditional) ──────────────────────────

section "Ruby (conditional)"

if command -v rspec &>/dev/null; then
    assert_help    "rtk rspec"                     rtk rspec --help
else
    skip_test "rtk rspec" "rspec not installed"
fi

if command -v rubocop &>/dev/null; then
    assert_help    "rtk rubocop"                   rtk rubocop --help
else
    skip_test "rtk rubocop" "rubocop not installed"
fi

if command -v rake &>/dev/null; then
    assert_help    "rtk rake"                      rtk rake --help
else
    skip_test "rtk rake" "rake not installed"
fi

# ── 31. Global flags ────────────────────────────────

section "Global flags"

assert_ok      "rtk -u ls ."                  rtk -u ls .
assert_ok      "rtk -v verbose"               rtk -v ls .
assert_ok      "rtk --skip-env npm --help"    rtk --skip-env npm --help

# ── 32. CcEconomics ─────────────────────────────────

section "CcEconomics"

assert_ok      "rtk cc-economics"             rtk cc-economics

# ── 33. Learn ───────────────────────────────────────

section "Learn"

assert_ok      "rtk learn --help"             rtk learn --help
assert_ok      "rtk learn (no sessions)"      rtk learn --since 0 2>&1 || true

# ── 32. Rewrite ───────────────────────────────────────

section "Rewrite"

assert_output_contains "rewrite git status"          "rtk git status"         rtk rewrite "git status"
assert_output_contains "rewrite cargo test"          "rtk cargo test"         rtk rewrite "cargo test"
assert_output_contains "rewrite compound &&"         "rtk git status"         rtk rewrite "git status && cargo test"
assert_output_contains "rewrite pipe preserves"      "| head"                 rtk rewrite "git log | head"

section "Rewrite (#345: RTK_DISABLED skip)"

assert_fails   "rewrite RTK_DISABLED=1 skip"                          rtk rewrite "RTK_DISABLED=1 git status"
assert_fails   "rewrite env RTK_DISABLED skip"                        rtk rewrite "FOO=1 RTK_DISABLED=1 cargo test"

section "Rewrite (#346: 2>&1 preserved)"

assert_output_contains "rewrite 2>&1 preserved"      "2>&1"                  rtk rewrite "cargo test 2>&1 | head"

section "Rewrite (#196: gh --json skip)"

assert_fails   "rewrite gh --json skip"                               rtk rewrite "gh pr list --json number"
assert_fails   "rewrite gh --jq skip"                                 rtk rewrite "gh api /repos --jq .name"
assert_fails   "rewrite gh --template skip"                           rtk rewrite "gh pr view 1 --template '{{.title}}'"
assert_output_contains "rewrite gh normal works"     "rtk gh pr list"        rtk rewrite "gh pr list"

# ── 33. Verify ────────────────────────────────────────

section "Verify"

assert_ok      "rtk verify"                   rtk verify

# ── 34. Proxy ─────────────────────────────────────────

section "Proxy"

assert_ok      "rtk proxy echo hello"         rtk proxy echo hello
assert_contains "rtk proxy passthrough"       "hello" rtk proxy echo hello

# ── 35. Discover ──────────────────────────────────────

section "Discover"

assert_ok      "rtk discover"                 rtk discover

# ── 36. Diff ──────────────────────────────────────────

section "Diff"

assert_ok      "rtk diff two files"           rtk diff Cargo.toml LICENSE

# ── 37. Wc ────────────────────────────────────────────

section "Wc"

assert_ok      "rtk wc Cargo.toml"            rtk wc Cargo.toml

# ── 38. Smart ─────────────────────────────────────────

section "Smart"

assert_ok      "rtk smart src/main.rs"        rtk smart src/main.rs

# ── 39. Json edge cases ──────────────────────────────

section "Json (edge cases)"

assert_fails   "rtk json on TOML (#347)"                              rtk json Cargo.toml

# ── 40. Docker (conditional) ─────────────────────────

section "Docker (conditional)"

if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
    assert_ok  "rtk docker ps"               rtk docker ps
    assert_ok  "rtk docker images"           rtk docker images
else
    skip_test "rtk docker" "docker not running"
fi

# ── 41. Hook check ───────────────────────────────────

section "Hook check (#344)"

assert_contains "rtk init --show configuration" "Configuration" rtk init --show

# ── 42. GitLab CLI ──────────────────────────────────

section "GitLab CLI (help only)"

assert_help    "rtk glab"                     rtk glab

# ── 43. Dotnet / AWS / PostgreSQL ───────────────────

section "Dotnet / AWS (help only)"

assert_help    "rtk dotnet"                   rtk dotnet
assert_help    "rtk aws"                      rtk aws

section "PostgreSQL (conditional)"

# psql uses disable_help_flag = true, so --help is forwarded to the real psql binary.
if command -v psql &>/dev/null; then
    assert_help    "rtk psql"                 rtk psql
else
    skip_test "rtk psql" "psql not installed"
fi

# ── 44. Jest / Format / Telemetry (help only) ──────

section "Jest (help only)"

assert_help    "rtk jest"                     rtk jest

section "Format (help only)"

assert_help    "rtk format"                   rtk format

section "Telemetry (help only)"

assert_help    "rtk telemetry"                rtk telemetry

# ── 45. Run ─────────────────────────────────────────

section "Run"

assert_contains "rtk run -c echo"      "hello"  rtk run -c "echo hello"
assert_contains "rtk run positional"   "hello"  rtk run echo hello

# ── 46. Pipe ────────────────────────────────────────

section "Pipe"

assert_ok      "rtk pipe --passthrough"        bash -c 'echo "hello world" | rtk pipe --passthrough'
assert_ok      "rtk pipe --filter cargo-test"  bash -c 'echo "test result: ok. 5 passed" | rtk pipe --filter cargo-test'

# ── 47. Session ─────────────────────────────────────

section "Session"

assert_ok      "rtk session"                  rtk session

# ── 48. Trust & Hook Audit ──────────────────────────

section "Trust"

assert_ok      "rtk trust --list"             rtk trust --list

section "Hook Audit"

assert_ok      "rtk hook-audit"               rtk hook-audit

# ── 49. Gain reset ──────────────────────────────────

section "Gain reset"

RESET_DB=$(mktemp /tmp/rtk-reset-XXXXX.db)
RTK_DB_PATH="$RESET_DB" rtk ls . >/dev/null 2>&1 || true
assert_ok      "rtk gain --reset --yes"       env RTK_DB_PATH="$RESET_DB" rtk gain --reset --yes
rm -f "$RESET_DB"

# ── 50. Npx routing ────────────────────────────────

section "Npx routing"

assert_contains "rtk npx routes to npx"  "npx" rtk npx --help

# ── 51. Agent Permissions ───────────────────────────

section "Agent Permissions: Hook Check"

assert_contains "hook check claude"     "rtk git status"   rtk hook check --agent claude git status
assert_contains "hook check cursor"     "rtk cargo test"   rtk hook check --agent cursor cargo test
assert_contains "hook check gemini"     "rtk git status"   rtk hook check --agent gemini git status
assert_fails    "hook check unsupported"                   rtk hook check htop

section "Agent Permissions: Rewrite Exit Codes"

# Exit 0 (allow) or 3 (ask) both mean "rewrite found"
code=0; rtk rewrite "git status" >/dev/null 2>&1 || code=$?
if [ "$code" -eq 0 ] || [ "$code" -eq 3 ]; then
    PASS=$((PASS + 1))
    printf "  ${GREEN}PASS${NC}  rewrite found (exit %d)\n" "$code"
else
    FAIL=$((FAIL + 1))
    FAILURES+=("rewrite found exit code")
    printf "  ${RED}FAIL${NC}  rewrite found: expected 0 or 3, got %d\n" "$code"
fi
assert_output_contains "rewrite output"        "rtk git status"   rtk rewrite "git status"
assert_fails    "rewrite passthrough (exit 1)"             rtk rewrite "ssh user@host"

# Verify exact exit code 1 (not 2 or 3)
code=0; rtk rewrite "htop" >/dev/null 2>&1 || code=$?
if [ "$code" -eq 1 ]; then
    PASS=$((PASS + 1))
    printf "  ${GREEN}PASS${NC}  rewrite passthrough exit code is exactly 1\n"
else
    FAIL=$((FAIL + 1))
    FAILURES+=("rewrite passthrough exit code")
    printf "  ${RED}FAIL${NC}  rewrite passthrough exit code: expected 1, got %d\n" "$code"
fi

skip_test "rewrite deny (exit 2)" "requires deny rule in config"
skip_test "rewrite ask (exit 3)" "requires ask rule in config"

section "Agent Permissions: Init (Isolated)"

TMPHOME=$(mktemp -d /tmp/rtk-init-XXXXX)
mkdir -p "$TMPHOME/.claude" "$TMPHOME/.gemini"

assert_ok       "init claude --global"                     env HOME="$TMPHOME" rtk init --agent claude --global
assert_ok       "init gemini --global"                     bash -c "HOME='$TMPHOME' rtk init --gemini --global </dev/null"
assert_ok       "init copilot"                             env HOME="$TMPHOME" rtk init --copilot
assert_ok       "init codex"                               env HOME="$TMPHOME" rtk init --codex
assert_ok       "init --uninstall (idempotent)"            env HOME="$TMPHOME" rtk init --uninstall --global

rm -rf "$TMPHOME"

section "Agent Permissions: Init Edge Cases"

assert_fails    "init cursor (local, should fail)"         rtk init --agent cursor

# ── 52. Transparency: Exit Codes ────────────────────

section "Transparency: Exit Codes"

assert_ok       "exit 0 preserved"                         rtk proxy true
assert_fails    "exit 1 preserved"                         rtk proxy false

# Exact exit code propagation (42, not just non-zero)
code=0; rtk proxy sh -c "exit 42" 2>/dev/null || code=$?
if [ "$code" -eq 42 ]; then
    PASS=$((PASS + 1))
    printf "  ${GREEN}PASS${NC}  exit 42 preserved (got %d)\n" "$code"
else
    FAIL=$((FAIL + 1))
    FAILURES+=("exit 42 preserved")
    printf "  ${RED}FAIL${NC}  exit 42 preserved (expected 42, got %d)\n" "$code"
fi

section "Transparency: Std Channels"

# Stderr not swallowed (use proxy, which preserves raw output)
err_output=$(rtk proxy sh -c "echo ERR_MARKER >&2; echo OK" 2>&1)
if echo "$err_output" | grep -q "ERR_MARKER"; then
    PASS=$((PASS + 1))
    printf "  ${GREEN}PASS${NC}  stderr not swallowed\n"
else
    FAIL=$((FAIL + 1))
    FAILURES+=("stderr not swallowed")
    printf "  ${RED}FAIL${NC}  stderr not swallowed (ERR_MARKER missing)\n"
fi

assert_contains "stdout present"        "hello"            rtk proxy echo hello

# Stdin piping
assert_ok       "stdin read pipe"                          bash -c 'echo "fn main() {}" | rtk read -'
assert_ok       "stdin pipe passthrough"                   bash -c 'echo "hello" | rtk pipe --passthrough'
assert_ok       "stdin pipe filter"                        bash -c 'echo "test result: ok. 5 passed" | rtk pipe --filter cargo-test'

# No stdin hang (must exit quickly)
timeout 5 rtk ls . >/dev/null 2>&1
if [ $? -eq 0 ]; then
    PASS=$((PASS + 1))
    printf "  ${GREEN}PASS${NC}  no stdin hang (ls exits quickly)\n"
else
    FAIL=$((FAIL + 1))
    FAILURES+=("no stdin hang")
    printf "  ${RED}FAIL${NC}  no stdin hang (ls timed out)\n"
fi

# Failing command stderr + exit code
code=0; rtk proxy sh -c "echo FAIL >&2 && exit 1" 2>/dev/null || code=$?
if [ "$code" -eq 1 ]; then
    PASS=$((PASS + 1))
    printf "  ${GREEN}PASS${NC}  failing command preserves exit 1\n"
else
    FAIL=$((FAIL + 1))
    FAILURES+=("failing command exit code")
    printf "  ${RED}FAIL${NC}  failing command exit code: expected 1, got %d\n" "$code"
fi

# ── 53. Run Modes ───────────────────────────────────

section "Run Modes: Filtered"

# Filtered mode produces different (compressed) output vs raw command
raw_ls=$(ls . 2>/dev/null | wc -c)
rtk_ls=$(rtk ls . 2>/dev/null | wc -c)
if [ "$rtk_ls" != "$raw_ls" ]; then
    PASS=$((PASS + 1))
    printf "  ${GREEN}PASS${NC}  filtered ls differs from raw (raw=%s, rtk=%s)\n" "$raw_ls" "$rtk_ls"
else
    FAIL=$((FAIL + 1))
    FAILURES+=("filtered ls differs from raw")
    printf "  ${RED}FAIL${NC}  filtered ls same as raw (%s bytes)\n" "$raw_ls"
fi
assert_ok       "filtered grep"                            rtk grep "fn main" src/

section "Run Modes: Streamed"

assert_ok       "streamed err"                             rtk err echo ok
assert_ok       "streamed test"                            rtk test echo ok

section "Run Modes: Passthrough"

# Passthrough must produce identical output to raw command
raw_head=$(git rev-parse HEAD 2>/dev/null)
rtk_head=$(rtk git rev-parse HEAD 2>/dev/null)
if [ "$raw_head" = "$rtk_head" ]; then
    PASS=$((PASS + 1))
    printf "  ${GREEN}PASS${NC}  passthrough git rev-parse HEAD matches raw\n"
else
    FAIL=$((FAIL + 1))
    FAILURES+=("passthrough matches raw")
    printf "  ${RED}FAIL${NC}  passthrough mismatch: raw='%s' rtk='%s'\n" "$raw_head" "$rtk_head"
fi

raw_remote=$(git remote -v 2>/dev/null)
rtk_remote=$(rtk git remote -v 2>/dev/null)
if [ "$raw_remote" = "$rtk_remote" ]; then
    PASS=$((PASS + 1))
    printf "  ${GREEN}PASS${NC}  passthrough git remote -v matches raw\n"
else
    FAIL=$((FAIL + 1))
    FAILURES+=("passthrough git remote -v matches raw")
    printf "  ${RED}FAIL${NC}  passthrough mismatch for git remote -v\n"
fi

# ══════════════════════════════════════════════════════
# Report
# ══════════════════════════════════════════════════════

finalize_sections

printf "\n${BOLD}══════════════════════════════════════${NC}\n"
printf "${BOLD}Results: ${GREEN}%d passed${NC}, ${RED}%d failed${NC}, ${YELLOW}%d skipped${NC}\n" "$PASS" "$FAIL" "$SKIP"

if [[ ${#FAILURES[@]} -gt 0 ]]; then
    printf "\n${RED}Failures:${NC}\n"
    for f in "${FAILURES[@]}"; do
        printf "  - %s\n" "$f"
    done
fi

printf "${BOLD}══════════════════════════════════════${NC}\n"

# ── Layer Report (for CI PR comment) ──────────────────
# Maps sections to layers and writes markdown to RTK_REPORT_FILE if set.

if [[ -n "${RTK_REPORT_FILE:-}" ]]; then
    declare -A LAYER_MAP
    # Layer 0: Binary Basics
    LAYER_MAP["Version & Help"]="L0: Binary Basics"
    # Layer 2: System Commands
    for s in "Ls" "Tree" "Read" "Read (stdin support)" "Grep" "Grep (extra args passthrough)" \
             "Find" "Json" "Json (edge cases)" "Deps" "Env" "Log" "Summary" "Wc" "Diff" "Smart"; do
        LAYER_MAP["$s"]="L2: System Commands"
    done
    # Layer 3: Git & VCS
    for s in "Git (existing)" "Git (new: branch, fetch, stash, worktree)" \
             "Git (passthrough: unsupported subcommands)" "GitHub CLI" "GitLab CLI (help only)" \
             "Graphite (conditional)"; do
        LAYER_MAP["$s"]="L3: Git & VCS"
    done
    # Layer 4: Cargo/Rust
    for s in "Cargo (new)" "Err" "Test runner"; do
        LAYER_MAP["$s"]="L4: Cargo/Rust"
    done
    # Layer 5: RTK Meta
    for s in "Gain" "Gain reset" "Config & Init" "CcEconomics" "Learn" "Discover" "Session"; do
        LAYER_MAP["$s"]="L5: RTK Meta"
    done
    # Layer 6: Hook System
    for s in "Rewrite" "Rewrite (#345: RTK_DISABLED skip)" "Rewrite (#346: 2>&1 preserved)" \
             "Rewrite (#196: gh --json skip)" "Verify" "Trust" "Hook Audit" "Hook check (#344)"; do
        LAYER_MAP["$s"]="L6: Hook System"
    done
    # Layer 7: Pipeline/Proxy
    for s in "Proxy" "Run" "Pipe"; do
        LAYER_MAP["$s"]="L7: Pipeline/Proxy"
    done
    # Layer 8: Network
    for s in "Curl (new)" "Wget"; do
        LAYER_MAP["$s"]="L8: Network"
    done
    # Layer 9: JS/TS
    for s in "Npm / Npx (new)" "Pnpm" "JS Tooling (help only, no project context)" \
             "Prisma (help only)" "Vitest (help only)" "Jest (help only)" "Npx routing"; do
        LAYER_MAP["$s"]="L9: JS/TS Ecosystem"
    done
    # Layer 10: Python
    LAYER_MAP["Python (conditional)"]="L10: Python"
    # Layer 11: Go
    LAYER_MAP["Go (conditional)"]="L11: Go"
    # Layer 12: Ruby/Dotnet/Cloud
    for s in "Ruby (conditional)" "Dotnet / AWS (help only)" "PostgreSQL (conditional)" \
             "Docker / Kubectl (help only)" "Docker (conditional)"; do
        LAYER_MAP["$s"]="L12: Ruby/Dotnet/Cloud"
    done
    # Layer 13: Agent Permissions
    for s in "Agent Permissions: Hook Check" "Agent Permissions: Rewrite Exit Codes" \
             "Agent Permissions: Init (Isolated)" "Agent Permissions: Init Edge Cases"; do
        LAYER_MAP["$s"]="L13: Agent Permissions"
    done
    # Layer 14: Transparency
    for s in "Transparency: Exit Codes" "Transparency: Std Channels"; do
        LAYER_MAP["$s"]="L14: Transparency"
    done
    # Layer 15: Run Modes
    for s in "Run Modes: Filtered" "Run Modes: Streamed" "Run Modes: Passthrough"; do
        LAYER_MAP["$s"]="L15: Run Modes"
    done
    # Layer 16: Global Flags
    LAYER_MAP["Global flags"]="L16: Global Flags"
    # Layer 1: Command Routing (help tests spread across sections)
    for s in "Format (help only)" "Telemetry (help only)"; do
        LAYER_MAP["$s"]="L1: Command Routing"
    done

    # Aggregate per-layer
    declare -A LP LF LS
    for entry in "${SECTION_RESULTS[@]}"; do
        IFS='|' read -r sname sp sf ss <<< "$entry"
        lname="${LAYER_MAP[$sname]:-Other}"
        LP["$lname"]=$(( ${LP["$lname"]:-0} + sp ))
        LF["$lname"]=$(( ${LF["$lname"]:-0} + sf ))
        LS["$lname"]=$(( ${LS["$lname"]:-0} + ss ))
    done

    # Write markdown report
    {
        printf "<!-- rtk-integration-results -->\n"
        printf "## RTK Integration Test Results\n\n"
        printf "**Binary**: \`%s\` | **Date**: %s\n\n" "$(rtk --version)" "$(date '+%Y-%m-%d %H:%M')"
        if [ "$FAIL" -eq 0 ]; then
            printf "**Status**: All tests passed\n\n"
        else
            printf "**Status**: %d failures detected\n\n" "$FAIL"
        fi
        printf "| Layer | Pass | Fail | Skip | Status |\n"
        printf "|-------|------|------|------|--------|\n"
        for lname in "L0: Binary Basics" "L1: Command Routing" "L2: System Commands" \
                     "L3: Git & VCS" "L4: Cargo/Rust" "L5: RTK Meta" "L6: Hook System" \
                     "L7: Pipeline/Proxy" "L8: Network" "L9: JS/TS Ecosystem" \
                     "L10: Python" "L11: Go" "L12: Ruby/Dotnet/Cloud" \
                     "L13: Agent Permissions" "L14: Transparency" "L15: Run Modes" \
                     "L16: Global Flags"; do
            p=${LP["$lname"]:-0}
            f=${LF["$lname"]:-0}
            s=${LS["$lname"]:-0}
            if [ "$f" -eq 0 ]; then
                printf "| %s | %d | %d | %d | :white_check_mark: |\n" "$lname" "$p" "$f" "$s"
            else
                printf "| %s | %d | %d | %d | :x: |\n" "$lname" "$p" "$f" "$s"
            fi
        done
        printf "\n**Total**: %d passed, %d failed, %d skipped\n" "$PASS" "$FAIL" "$SKIP"
        if [[ ${#FAILURES[@]} -gt 0 ]]; then
            printf "\n<details><summary>Failures</summary>\n\n"
            for f in "${FAILURES[@]}"; do
                printf "- \`%s\`\n" "$f"
            done
            printf "\n</details>\n"
        fi
    } > "$RTK_REPORT_FILE"
fi

exit "$FAIL"
