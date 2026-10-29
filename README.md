# qahq

Quality-assurance headquarters. One flake that packages the lint/QA CLI tools,
so each project wires a single input instead of copy-pasting `fetchCrate`/`naersk`
blocks and juggling four or five tool inputs.

## Tools

| Tool | Party | Source | Purpose |
|---|---|---|---|
| `canibump` | first | `github:mlavrinenko/canibump` | says which upstream-blocked workarounds you can drop |
| `ejectest` | first | `github:mlavrinenko/ejectest` | ejects inline tests into sibling files |
| `linecop` | first | `github:mlavrinenko/linecop` | enforces line count limits |
| `mindtape` | first | `github:mlavrinenko/mindtape` | file-based task tracker (`mt`) whose `mt check` gates tasks and commits |
| `mmz` | first | `github:mlavrinenko/mmz` | memoized command runner |
| `outdatty` | first | `github:mlavrinenko/outdatty` | catches outdated artifacts via a dependency graph and content hashes |
| `cargo-crap` | third | crates.io, vendored in `pkgs/` | CRAP change-risk metric gate |
| `jscpd` | third | `github:mlavrinenko/jscpd` fork of its flake | copy/paste detector |

First-party tools are ours. Each comes from its own flake, and its name sits in
`firstParty` in `flake.nix`. `just bump` and `just changelog` read that list.
Third-party tools sit in `thirdParty`. A tool with an upstream flake comes from
it. One without gets a portable, nixpkgs-style derivation in `pkgs/*.nix`.

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

CI pushes every built tool to `https://qahq.cachix.org`. Trust it once, system
wide, and you download binaries instead of compiling Rust:

```nix
nix.settings = {
  extra-substituters = [ "https://qahq.cachix.org" ];
  extra-trusted-public-keys = [
    "qahq.cachix.org-1:m43yxxOk1vih9jTZmKXZXgHSSKsW/rNVZUqgXqrELM8="
  ];
};
```

The flake ships no `nixConfig` on purpose. Nix ignores it on an input anyway,
and where it does apply it prints `Using saved setting` on every command.

## Maintenance

Add a third-party tool:

1. Write `pkgs/<tool>.nix` as a `callPackage` derivation (see `cargo-crap.nix`
   for `rustPlatform`).
2. Wire it in `flake.nix`: `callPackage ./pkgs/<tool>.nix { }` in
   `thirdParty`.
3. `git add` (flake commands ignore untracked files), then `nix build .#<tool>`.

Bump a version: change `version` + `hash` (and `cargoHash` for `rustPlatform`),
set the hash to `""` or `lib.fakeHash` first, rebuild, and copy the real hash
from the mismatch error.

Re-export a new first-party tool. Add its flake input with
`inputs.nixpkgs.follows = "nixpkgs"`, plus `inputs.qahq.follows = ""` if it has
a `qahq` input. Then name it in the `outputs` pattern and in `firstParty`.

`just check` lints the Nix too. deadnix, statix and nixfmt run as
`checks.lint`, so dead code, an input nothing uses or a formatting slip fails
the gate here and in CI.

## License

MIT. See `LICENSE-MIT`.
