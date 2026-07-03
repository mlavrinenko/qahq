# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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

[Unreleased]: https://github.com/mlavrinenko/qahq/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/mlavrinenko/qahq/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/mlavrinenko/qahq/releases/tag/v0.1.0
