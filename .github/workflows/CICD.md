# rtk-tx CI/CD Flows

This fork keeps CI/CD inside GitHub Actions and GitHub Releases. It does not publish to crates.io, Homebrew, npm, Docker, winget, Discord, or any external distribution channel.

## PR Quality Gates (`ci.yml`)

Trigger: pull requests targeting `develop` or `master`.

Main checks:

- `cargo fmt --all -- --check`
- `cargo clippy --all-targets -- -D unsafe_code`
- `cargo test --all` on Linux, macOS, and Windows
- security scan, Semgrep, benchmark, and documentation review jobs

The benchmark job builds the `rtk-tx` release binary before running smoke benchmarks.

## Push / Manual Release Orchestration (`cd.yml`)

Triggers:

- push to `develop`: compute a pre-release tag and call `release.yml`
- push to `master`: run release-please for `rtk-tx`, then call `release.yml` if a release is created
- `workflow_dispatch`: manually trigger the same release orchestration

`release-please` uses package name `rtk-tx`.

## GitHub Release Builder (`release.yml`)

Triggers:

- called by `cd.yml`
- manual `workflow_dispatch` with `tag` and `prerelease`

Build outputs:

- `rtk-tx-x86_64-apple-darwin.tar.gz`
- `rtk-tx-aarch64-apple-darwin.tar.gz`
- `rtk-tx-x86_64-unknown-linux-musl.tar.gz`
- `rtk-tx-aarch64-unknown-linux-gnu.tar.gz`
- `rtk-tx-x86_64-pc-windows-msvc.zip`
- DEB and RPM packages
- `checksums.txt`

The release workflow uploads artifacts only to the GitHub Release for this repository.

## Installer Flow (`install.sh`)

`install.sh` downloads from GitHub Releases in `Kayphoon/rtk-tx`.

Example:

```bash
curl -fsSL https://raw.githubusercontent.com/Kayphoon/rtk-tx/master/install.sh | sh
```

Pin a version:

```bash
RTK_TX_VERSION=v0.34.3 sh ./install.sh
```

The installer detects OS/architecture, downloads the matching `rtk-tx-${target}.tar.gz`, verifies `checksums.txt` when available, and installs `rtk-tx` into `${RTK_INSTALL_DIR:-$HOME/.local/bin}`.

## External Platform Publishing

Publishing to crates.io, Homebrew, Docker/GHCR, winget, npm, or distro package repositories is intentionally out of scope for this repo-internal CI/CD setup. Those channels require separate accounts, package ownership, tokens, signing, and platform-specific review workflows.
