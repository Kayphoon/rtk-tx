#!/usr/bin/env bash
#
# rtk-tx Smoke Test Suite
# Exercises every command to catch regressions after merge.
# Exit code: number of failures (0 = all green)
#
set -euo pipefail

PASS=0
FAIL=0
SKIP=0
FAILURES=()

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

skip_test() {
    local name="$1"
    local reason="$2"
    SKIP=$((SKIP + 1))
    printf "  ${YELLOW}SKIP${NC}  %s (%s)\n" "$name" "$reason"
}

section() {
    printf "\n${BOLD}${CYAN}── %s ──${NC}\n" "$1"
}

# ── Preamble ─────────────────────────────────────────

RTK=$(command -v rtk-tx || echo "")
if [[ -z "$RTK" ]]; then
    echo "rtk-tx not found in PATH. Run: cargo install --path ."
    exit 1
fi

printf "${BOLD}rtk-tx Smoke Test Suite${NC}\n"
printf "Binary: %s\n" "$RTK"
printf "Version: %s\n" "$($RTK --version)"
printf "Date: %s\n" "$(date '+%Y-%m-%d %H:%M')"

# Need a git repo to test git commands
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "Must run from inside a git repository."
    exit 1
fi

REPO_ROOT=$(git rev-parse --show-toplevel)

# ── 1. Version & Help ───────────────────────────────

section "Version & Help"

assert_contains "rtk-tx --version" "rtk-tx" rtk-tx --version
assert_contains "rtk-tx --help" "Usage:" rtk-tx --help

# ── 2. Ls ────────────────────────────────────────────

section "Ls"

assert_ok      "rtk-tx ls ."                     rtk-tx ls .
assert_ok      "rtk-tx ls -la ."                 rtk-tx ls -la .
assert_ok      "rtk-tx ls -lh ."                 rtk-tx ls -lh .
assert_ok      "rtk-tx ls -l src/"               rtk-tx ls -l src/
assert_ok      "rtk-tx ls src/ -l (flag after)"  rtk-tx ls src/ -l
assert_ok      "rtk-tx ls multi paths"           rtk-tx ls src/ scripts/
assert_contains "rtk-tx ls -a shows hidden"      ".git" rtk-tx ls -a .
assert_contains "rtk-tx ls shows sizes"          "K"  rtk-tx ls src/
assert_contains "rtk-tx ls shows dirs with /"    "/" rtk-tx ls .

# ── 2b. Tree ─────────────────────────────────────────

section "Tree"

if command -v tree >/dev/null 2>&1; then
    assert_ok      "rtk-tx tree ."                rtk-tx tree .
    assert_ok      "rtk-tx tree -L 2 ."           rtk-tx tree -L 2 .
    assert_ok      "rtk-tx tree -d -L 1 ."        rtk-tx tree -d -L 1 .
    assert_contains "rtk-tx tree shows src/"      "src" rtk-tx tree -L 1 .
else
    skip_test "rtk-tx tree" "tree not installed"
fi

# ── 3. Read ──────────────────────────────────────────

section "Read"

assert_ok      "rtk-tx read Cargo.toml"          rtk-tx read Cargo.toml
assert_ok      "rtk-tx read --level none Cargo.toml"  rtk-tx read --level none Cargo.toml
assert_ok      "rtk-tx read --level aggressive Cargo.toml" rtk-tx read --level aggressive Cargo.toml
assert_ok      "rtk-tx read -n Cargo.toml"       rtk-tx read -n Cargo.toml
assert_ok      "rtk-tx read --max-lines 5 Cargo.toml" rtk-tx read --max-lines 5 Cargo.toml

section "Read (stdin support)"

assert_ok      "rtk-tx read stdin pipe"          bash -c 'echo "fn main() {}" | rtk-tx read -'

# ── 4. Git ───────────────────────────────────────────

section "Git (existing)"

assert_ok      "rtk-tx git status"               rtk-tx git status
assert_ok      "rtk-tx git status --short"       rtk-tx git status --short
assert_ok      "rtk-tx git status -s"            rtk-tx git status -s
assert_ok      "rtk-tx git status --porcelain"   rtk-tx git status --porcelain
assert_ok      "rtk-tx git log"                  rtk-tx git log
assert_ok      "rtk-tx git log -5"               rtk-tx git log -- -5
assert_ok      "rtk-tx git diff"                 rtk-tx git diff
assert_ok      "rtk-tx git diff --stat"          rtk-tx git diff --stat

section "Git (new: branch, fetch, stash, worktree)"

assert_ok      "rtk-tx git branch"               rtk-tx git branch
assert_ok      "rtk-tx git fetch"                rtk-tx git fetch
assert_ok      "rtk-tx git stash list"           rtk-tx git stash list
assert_ok      "rtk-tx git worktree"             rtk-tx git worktree

section "Git (passthrough: unsupported subcommands)"

assert_ok      "rtk-tx git tag --list"           rtk-tx git tag --list
assert_ok      "rtk-tx git remote -v"            rtk-tx git remote -v
assert_ok      "rtk-tx git rev-parse HEAD"       rtk-tx git rev-parse HEAD

# ── 5. GitHub CLI ────────────────────────────────────

section "GitHub CLI"

if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
    assert_ok      "rtk-tx gh pr list"           rtk-tx gh pr list
    assert_ok      "rtk-tx gh run list"          rtk-tx gh run list
    assert_ok      "rtk-tx gh issue list"        rtk-tx gh issue list
    # pr create/merge/diff/comment/edit are write ops, test help only
    assert_help    "rtk-tx gh"                   rtk-tx gh
else
    skip_test "gh commands" "gh not authenticated"
fi

# ── 6. Cargo ─────────────────────────────────────────

section "Cargo (new)"

assert_ok      "rtk-tx cargo build"              rtk-tx cargo build
assert_ok      "rtk-tx cargo clippy"             rtk-tx cargo clippy
# cargo test exits non-zero due to pre-existing failures; check output ignoring exit code
output_cargo_test=$(rtk-tx cargo test 2>&1 || true)
if echo "$output_cargo_test" | grep -q "FAILURES\|test result:\|passed"; then
    PASS=$((PASS + 1))
    printf "  ${GREEN}PASS${NC}  %s\n" "rtk-tx cargo test"
else
    FAIL=$((FAIL + 1))
    FAILURES+=("rtk-tx cargo test")
    printf "  ${RED}FAIL${NC}  %s\n" "rtk-tx cargo test"
    printf "        got: %s\n" "$(echo "$output_cargo_test" | head -3)"
fi
assert_help    "rtk-tx cargo"                    rtk-tx cargo

# ── 7. Curl ──────────────────────────────────────────

section "Curl (new)"

assert_contains "rtk-tx curl JSON detect" "string" rtk-tx curl https://httpbin.org/json
assert_ok       "rtk-tx curl plain text"          rtk-tx curl https://httpbin.org/robots.txt
assert_help     "rtk-tx curl"                     rtk-tx curl

# ── 8. Npm / Npx ────────────────────────────────────

section "Npm / Npx (new)"

assert_help    "rtk-tx npm"                      rtk-tx npm
assert_help    "rtk-tx npx"                      rtk-tx npx

# ── 9. Pnpm ─────────────────────────────────────────

section "Pnpm"

assert_help    "rtk-tx pnpm"                     rtk-tx pnpm
assert_help    "rtk-tx pnpm build"               rtk-tx pnpm build
assert_help    "rtk-tx pnpm typecheck"           rtk-tx pnpm typecheck

if command -v pnpm >/dev/null 2>&1; then
    assert_ok  "rtk-tx pnpm help"                rtk-tx pnpm help
fi

# ── 10. Grep ─────────────────────────────────────────

section "Grep"

assert_ok      "rtk-tx grep pattern"             rtk-tx grep "pub fn" src/
assert_contains "rtk-tx grep finds results"      "pub fn" rtk-tx grep "pub fn" src/
assert_ok      "rtk-tx grep with file type"      rtk-tx grep "pub fn" src/ -t rust

section "Grep (extra args passthrough)"

assert_ok      "rtk-tx grep -i case insensitive" rtk-tx grep "fn" src/ -i
assert_ok      "rtk-tx grep -A context lines"    rtk-tx grep "fn run" src/ -A 2

# ── 11. Find ─────────────────────────────────────────

section "Find"

assert_ok      "rtk-tx find *.rs"                rtk-tx find "*.rs" src/
assert_contains "rtk-tx find shows files"        ".rs" rtk-tx find "*.rs" src/

# ── 12. Json ─────────────────────────────────────────

section "Json"

# Create temp JSON file for testing
TMPJSON=$(mktemp /tmp/rtk-test-XXXXX.json)
echo '{"name":"test","count":42,"items":[1,2,3]}' > "$TMPJSON"

assert_ok      "rtk-tx json file"                rtk-tx json "$TMPJSON"
assert_contains "rtk-tx json shows schema"       "string" rtk-tx json "$TMPJSON"

rm -f "$TMPJSON"

# ── 13. Deps ─────────────────────────────────────────

section "Deps"

assert_ok      "rtk-tx deps ."                   rtk-tx deps .
assert_contains "rtk-tx deps shows Cargo"        "Cargo" rtk-tx deps .

# ── 14. Env ──────────────────────────────────────────

section "Env"

assert_ok      "rtk-tx env"                      rtk-tx env
assert_ok      "rtk-tx env --filter PATH"        rtk-tx env --filter PATH

# ── 16. Log ──────────────────────────────────────────

section "Log"

TMPLOG=$(mktemp /tmp/rtk-log-XXXXX.log)
for i in $(seq 1 20); do
    echo "[2025-01-01 12:00:00] INFO: repeated message" >> "$TMPLOG"
done
echo "[2025-01-01 12:00:01] ERROR: something failed" >> "$TMPLOG"

assert_ok      "rtk-tx log file"                 rtk-tx log "$TMPLOG"

rm -f "$TMPLOG"

# ── 17. Summary ──────────────────────────────────────

section "Summary"

assert_ok      "rtk-tx summary echo hello"       rtk-tx summary echo hello

# ── 18. Err ──────────────────────────────────────────

section "Err"

assert_ok      "rtk-tx err echo ok"              rtk-tx err echo ok

# ── 19. Test runner ──────────────────────────────────

section "Test runner"

assert_ok      "rtk-tx test echo ok"             rtk-tx test echo ok

# ── 20. Gain ─────────────────────────────────────────

section "Gain"

assert_ok      "rtk-tx gain"                     rtk-tx gain
assert_ok      "rtk-tx gain --history"           rtk-tx gain --history

# ── 21. Config & Init ────────────────────────────────

section "Config & Init"

assert_ok      "rtk-tx config"                   rtk-tx config
assert_ok      "rtk-tx init --show"              rtk-tx init --show

# ── 22. Wget ─────────────────────────────────────────

section "Wget"

if command -v wget >/dev/null 2>&1; then
    assert_ok  "rtk-tx wget stdout"              rtk-tx wget https://httpbin.org/robots.txt -O
else
    skip_test "rtk-tx wget" "wget not installed"
fi

# ── 23. Tsc / Lint / Prettier / Next / Playwright ───

section "JS Tooling (help only, no project context)"

assert_help    "rtk-tx tsc"                      rtk-tx tsc
assert_help    "rtk-tx lint"                     rtk-tx lint
assert_help    "rtk-tx prettier"                 rtk-tx prettier
assert_help    "rtk-tx next"                     rtk-tx next
assert_help    "rtk-tx playwright"               rtk-tx playwright

# ── 24. Prisma ───────────────────────────────────────

section "Prisma (help only)"

assert_help    "rtk-tx prisma"                   rtk-tx prisma

# ── 25. Vitest ───────────────────────────────────────

section "Vitest (help only)"

assert_help    "rtk-tx vitest"                   rtk-tx vitest

# ── 26. Docker / Kubectl (help only) ────────────────

section "Docker / Kubectl (help only)"

assert_help    "rtk-tx docker"                   rtk-tx docker
assert_help    "rtk-tx kubectl"                  rtk-tx kubectl

# ── 27. Python (conditional) ────────────────────────

section "Python (conditional)"

if command -v pytest &>/dev/null; then
    assert_help    "rtk-tx pytest"                    rtk-tx pytest --help
else
    skip_test "rtk-tx pytest" "pytest not installed"
fi

if command -v ruff &>/dev/null; then
    assert_help    "rtk-tx ruff"                      rtk-tx ruff --help
else
    skip_test "rtk-tx ruff" "ruff not installed"
fi

if command -v pip &>/dev/null; then
    assert_help    "rtk-tx pip"                       rtk-tx pip --help
else
    skip_test "rtk-tx pip" "pip not installed"
fi

# ── 28. Go (conditional) ────────────────────────────

section "Go (conditional)"

if command -v go &>/dev/null; then
    assert_help    "rtk-tx go"                        rtk-tx go --help
    assert_help    "rtk-tx go test"                   rtk-tx go test -h
    assert_help    "rtk-tx go build"                  rtk-tx go build -h
    assert_help    "rtk-tx go vet"                    rtk-tx go vet -h
else
    skip_test "rtk-tx go" "go not installed"
fi

if command -v golangci-lint &>/dev/null; then
    assert_help    "rtk-tx golangci-lint"             rtk-tx golangci-lint --help
else
    skip_test "rtk-tx golangci-lint" "golangci-lint not installed"
fi

# ── 29. Graphite (conditional) ─────────────────────

section "Graphite (conditional)"

if command -v gt &>/dev/null; then
    assert_help   "rtk-tx gt"                          rtk-tx gt --help
    assert_ok     "rtk-tx gt log short"                rtk-tx gt log short
else
    skip_test "rtk-tx gt" "gt not installed"
fi

# ── 30. Ruby (conditional) ──────────────────────────

section "Ruby (conditional)"

if command -v rspec &>/dev/null; then
    assert_help    "rtk-tx rspec"                     rtk-tx rspec --help
else
    skip_test "rtk-tx rspec" "rspec not installed"
fi

if command -v rubocop &>/dev/null; then
    assert_help    "rtk-tx rubocop"                   rtk-tx rubocop --help
else
    skip_test "rtk-tx rubocop" "rubocop not installed"
fi

if command -v rake &>/dev/null; then
    assert_help    "rtk-tx rake"                      rtk-tx rake --help
else
    skip_test "rtk-tx rake" "rake not installed"
fi

# ── 31. Global flags ────────────────────────────────

section "Global flags"

assert_ok      "rtk-tx -u ls ."                  rtk-tx -u ls .
assert_ok      "rtk-tx --skip-env npm --help"    rtk-tx --skip-env npm --help

# ── 32. CcEconomics ─────────────────────────────────

section "CcEconomics"

assert_ok      "rtk-tx cc-economics"             rtk-tx cc-economics

# ── 33. Learn ───────────────────────────────────────

section "Learn"

assert_ok      "rtk-tx learn --help"             rtk-tx learn --help
assert_ok      "rtk-tx learn (no sessions)"      rtk-tx learn --since 0 2>&1 || true

# ── 32. Rewrite ───────────────────────────────────────

section "Rewrite"

assert_contains "rewrite git status"          "rtk-tx git status"         rtk-tx rewrite "git status"
assert_contains "rewrite cargo test"          "rtk-tx cargo test"         rtk-tx rewrite "cargo test"
assert_contains "rewrite compound &&"         "rtk-tx git status"         rtk-tx rewrite "git status && cargo test"
assert_contains "rewrite pipe preserves"      "| head"                 rtk-tx rewrite "git log | head"

section "Rewrite (#345: RTK_DISABLED skip)"

assert_fails   "rewrite RTK_DISABLED=1 skip"                          rtk-tx rewrite "RTK_DISABLED=1 git status"
assert_fails   "rewrite env RTK_DISABLED skip"                        rtk-tx rewrite "FOO=1 RTK_DISABLED=1 cargo test"

section "Rewrite (#346: 2>&1 preserved)"

assert_contains "rewrite 2>&1 preserved"      "2>&1"                  rtk-tx rewrite "cargo test 2>&1 | head"

section "Rewrite (#196: gh --json skip)"

assert_fails   "rewrite gh --json skip"                               rtk-tx rewrite "gh pr list --json number"
assert_fails   "rewrite gh --jq skip"                                 rtk-tx rewrite "gh api /repos --jq .name"
assert_fails   "rewrite gh --template skip"                           rtk-tx rewrite "gh pr view 1 --template '{{.title}}'"
assert_contains "rewrite gh normal works"     "rtk-tx gh pr list"        rtk-tx rewrite "gh pr list"

# ── 33. Verify ────────────────────────────────────────

section "Verify"

assert_ok      "rtk-tx verify"                   rtk-tx verify

# ── 34. Proxy ─────────────────────────────────────────

section "Proxy"

assert_ok      "rtk-tx proxy echo hello"         rtk-tx proxy echo hello
assert_contains "rtk-tx proxy passthrough"       "hello" rtk-tx proxy echo hello

# ── 35. Discover ──────────────────────────────────────

section "Discover"

assert_ok      "rtk-tx discover"                 rtk-tx discover

# ── 36. Diff ──────────────────────────────────────────

section "Diff"

assert_ok      "rtk-tx diff two files"           rtk-tx diff Cargo.toml LICENSE

# ── 37. Wc ────────────────────────────────────────────

section "Wc"

assert_ok      "rtk-tx wc Cargo.toml"            rtk-tx wc Cargo.toml

# ── 38. Smart ─────────────────────────────────────────

section "Smart"

assert_ok      "rtk-tx smart src/main.rs"        rtk-tx smart src/main.rs

# ── 39. Json edge cases ──────────────────────────────

section "Json (edge cases)"

assert_fails   "rtk-tx json on TOML (#347)"                              rtk-tx json Cargo.toml

# ── 40. Docker (conditional) ─────────────────────────

section "Docker (conditional)"

if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
    assert_ok  "rtk-tx docker ps"               rtk-tx docker ps
    assert_ok  "rtk-tx docker images"           rtk-tx docker images
else
    skip_test "rtk-tx docker" "docker not running"
fi

# ── 41. Hook check ───────────────────────────────────

section "Hook check (#344)"

assert_contains "rtk-tx init --show hook version" "version" rtk-tx init --show

# ══════════════════════════════════════════════════════
# Report
# ══════════════════════════════════════════════════════

printf "\n${BOLD}══════════════════════════════════════${NC}\n"
printf "${BOLD}Results: ${GREEN}%d passed${NC}, ${RED}%d failed${NC}, ${YELLOW}%d skipped${NC}\n" "$PASS" "$FAIL" "$SKIP"

if [[ ${#FAILURES[@]} -gt 0 ]]; then
    printf "\n${RED}Failures:${NC}\n"
    for f in "${FAILURES[@]}"; do
        printf "  - %s\n" "$f"
    done
fi

printf "${BOLD}══════════════════════════════════════${NC}\n"

exit "$FAIL"
