# AGENTS.md

qahq packages shared QA/lint CLI tools and re-exports them for the sibling Rust
projects. It is a Nix flake, not a Rust crate — no Cargo, no `src/`.

## Layout

- `flake.nix` — inputs, per-system `packages`/`devShells`, `overlays.default`.
- `pkgs/<tool>.nix` — one portable `callPackage` derivation per vendored
  third-party tool. Keep these nixpkgs-style so they stay upstream-ready.
- `.github/workflows/ci.yml` — `nix flake check` + build all + Cachix push.
- `Justfile` — see and use it. Add any repeatable and regular operations there.

## Rules

- Nix flake commands only see git-tracked files. `git add` new `pkgs/*.nix`
  before `nix build`/`nix flake check`, or they are invisible.
- Never re-vendor a tool that already ships a flake. Consume it as an input
  (with `inputs.nixpkgs.follows = "nixpkgs"`) and list it in `flakeTools`,
  regardless of who authored it. Only crates.io tools with no upstream flake
  get a vendored `pkgs/<tool>.nix`.
- Do not pin `RUSTC_WRAPPER`/sccache here. Host `kache` handles caching and
  never reaches the build sandbox.
- Every tool must land in the `tools` set so it flows into `default`, the
  devShell, and the overlay.

## Validate

```sh
just check             # evaluates + builds every tool, the bundle, devShell
just build <tool>      # one tool (defaults to the bundle)
just run <tool> -- ... # smoke-test a binary
```

## Commits

Conventional Commits, matching the sibling repos (`mmz`, `linecop`, …). No
`Refs:` footer — the family does not use one. Release commit bumps the tag.
Author `Lavrinenko Maxim <maxim@lavrinenko.xyz>`.
