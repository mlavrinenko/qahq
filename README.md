# qahq

Quality-assurance headquarters. One flake that packages the lint/QA CLI tools,
so each project wires a single input instead of copy-pasting `fetchCrate`/`naersk`
blocks and juggling four or five tool inputs.

## Tools

| Tool | Source | Purpose |
|---|---|---|
| `cargo-crap` | crates.io (third-party) | CRAP change-risk metric gate |
| `jscpd` | crates.io (third-party, Rust build) | copy/paste detector |
| `ejectest` | `github:mlavrinenko/ejectest` | re-exported first-party |
| `linecop` | `github:mlavrinenko/linecop` | re-exported first-party |
| `outdatty` | `github:mlavrinenko/outdatty` | re-exported first-party |
| `mmz` | `github:mlavrinenko/mmz` | re-exported first-party |

Third-party tools are vendored in `pkgs/*.nix` as portable, nixpkgs-style
derivations (upstream-ready). First-party tools are re-exported from their own
flakes, pinned together in this flake's lock.

## Use

Add one input:

```nix
inputs.qahq.url = "github:mlavrinenko/qahq";
```

Pick tools individually:

```nix
# devShell:
nativeBuildInputs = [
  qahq.packages.${system}.cargo-crap
  qahq.packages.${system}.linecop
  qahq.packages.${system}.ejectest
  qahq.packages.${system}.outdatty
];
```

or take the whole stack in one entry (`default` is a `buildEnv` with every tool
on PATH):

```nix
nativeBuildInputs = [ qahq.packages.${system}.default ];
```

or via overlay:

```nix
nixpkgs.overlays = [ qahq.overlays.default ];
# then: pkgs.qahq.cargo-crap, pkgs.qahq.jscpd, ...
```

Run ad hoc: `nix run github:mlavrinenko/qahq#jscpd -- --help`.

### Do not override the nixpkgs pin

qahq builds every tool against its own pinned `nixpkgs-unstable`. Leave it
alone — do NOT add `qahq.inputs.nixpkgs.follows = "nixpkgs"`. Following the
consumer's nixpkgs changes the derivation hashes and forces a from-source
rebuild of every tool, missing the binary cache. The cost of not following is a
second nixpkgs evaluation; the payoff is prebuilt binaries.

## Binary cache

CI pushes every built tool to `https://qahq.cachix.org`, so consumers download
binaries instead of compiling Rust from source.

## Maintenance

Add a third-party tool:

1. Write `pkgs/<tool>.nix` as a `callPackage` derivation (see `cargo-crap.nix`
   for `rustPlatform`, `jscpd.nix` for `naersk`).
2. Wire it in `flake.nix`: `callPackage ./pkgs/<tool>.nix { }` and add it to
   `tools`.
3. `git add` (flake commands ignore untracked files), then `nix build .#<tool>`.

Bump a version: change `version` + `hash` (and `cargoHash` for `rustPlatform`),
set the hash to `""` or `lib.fakeHash` first, rebuild, and copy the real hash
from the mismatch error.

Re-export a new first-party tool: add its flake input (with
`inputs.nixpkgs.follows = "nixpkgs"`) and one line in `firstParty`.

## License

MIT. See `LICENSE-MIT`.
