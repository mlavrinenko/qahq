# AGENTS.md

qahq packages shared QA/lint CLI tools and re-exports them for the sibling Rust
projects. It is a Nix flake, not a Rust crate — no Cargo, no `src/`.

## Layout

- `flake.nix` — inputs, per-system `packages`/`devShells`, `overlays.default`.
- `pkgs/<tool>.nix` — one portable `callPackage` derivation per vendored
  third-party tool. Keep these nixpkgs-style so they stay upstream-ready.
- `.github/workflows/ci.yml` — `nix flake check` + build all + Cachix push.

## Rules

- Nix flake commands only see git-tracked files. `git add` new `pkgs/*.nix`
  before `nix build`/`nix flake check`, or they are invisible.
- Keep third-party derivations in `pkgs/` (vendored crates.io tools). Re-export
  first-party tools from their own flakes in `firstParty` — never re-vendor a
  tool that already has a flake.
- Do not pin `RUSTC_WRAPPER`/sccache here. Host `kache` handles caching and
  never reaches the build sandbox.
- Every tool must land in the `tools` set so it flows into `default`, the
  devShell, and the overlay.

## Validate

```sh
nix flake check          # evaluates + builds every tool, the bundle, devShell
nix build .#<tool>       # one tool
nix run .#<tool> -- ...  # smoke-test a binary
```

## Commits

Conventional Commits, matching the sibling repos (`mmz`, `linecop`, …). No
`Refs:` footer — the family does not use one. Release commit bumps the tag.
Author `Lavrinenko Maxim <maxim@lavrinenko.xyz>`.
