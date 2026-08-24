# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.4.0] - 2026-08-24

### Changed

- First-party tools re-pinned from their own flakes (tool bumps below verified
  via `nix run .#<tool> -- --version`; the `default` bundle and devShell now
  carry the new binaries).
- `check` builds the full tool bundle (`.#default`) after flake evaluation, so
  CI catches a broken aggregation, not just per-tool builds.
- New `changelog` recipe: `just changelog` diffs `flake.lock` between the last
  release tag and the working tree and prints first-party tool-bump bullets. It
  reads the revisions via `.nodes.root.inputs.<tool>` — flake.lock dedupes
  shared nodes, so an input name is not necessarily its node name.

### Added

- `just bump` / `just bump-all` recipes that refresh inputs and commit the
  renewed `flake.lock`.

### Fixed

- `bump` passes `--tarball-ttl 0` so a stale nix cache entry cannot pin a tool
  to an old revision.

### Updated

- `mmz` v0.3.0 → v0.10.0 (rev `1b4593cf`).
- `linecop` v0.3.0 → v0.4.0.
- `outdatty` v0.3.0 → v0.4.0.
- `ejectest` → latest main (rev `564aac9`).
- `jscpd` pin advanced to `v5.0.15`.

## [0.3.0] - 2026-07-05

### Changed

- `jscpd` no longer vendored via `naersk` `singleStep` from the crates.io
  publish. It now ships its own flake (`crane` + `fenix`, `nixpkgs.follows`
  wired clean); qahq consumes it as an input pinned to `v5.0.11` instead.
  Verified: `nix flake check` green, `default` bundle carries the binary,
  clone detection confirmed on a real tree.
- Collapsed the first-party/third-party tool split into one `flakeTools`
  set — every tool consumed from its own flake belongs there regardless of
  authorship. `cargo-crap` stays vendored in `pkgs/` (no upstream flake).

## [0.2.0] - 2026-07-03

### Added

- Enable the Cachix binary cache: uncomment `nixConfig` with the real
  `qahq.cachix.org` public key now that `CACHIX_AUTH_TOKEN` is wired in CI.
  Verified end-to-end (a forced clean rebuild pushed every tool with no auth
  errors, and the pushed narinfos are independently fetchable).
- `Justfile` (`check`/`build`/`run` wrapping the nix commands) and `just` in
  `devShells.default`.

## [0.1.0] - 2026-07-03

### Added

- Initial release. One flake packaging the shared QA/lint CLI tools.
- Third-party tools vendored from crates.io as portable `pkgs/*.nix`
  derivations: `cargo-crap` (`rustPlatform`), `jscpd` (`naersk` `singleStep`).
- First-party tools re-exported from their own flakes, pinned together:
  `ejectest`, `linecop`, `outdatty`, `mmz`.
- Outputs: `packages.<system>.<tool>`, a `default` `buildEnv` bundle with every
  tool on PATH, `devShells.default`, and `overlays.default` (`pkgs.qahq.<tool>`).
- CI builds the whole stack and pushes to a Cachix binary cache (skipped until
  `CACHIX_AUTH_TOKEN` is set).

[Unreleased]: https://github.com/mlavrinenko/qahq/compare/v0.4.0...HEAD
[0.4.0]: https://github.com/mlavrinenko/qahq/compare/v0.3.0...v0.4.0
[0.3.0]: https://github.com/mlavrinenko/qahq/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/mlavrinenko/qahq/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/mlavrinenko/qahq/releases/tag/v0.1.0
