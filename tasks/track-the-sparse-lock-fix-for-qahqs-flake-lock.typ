#import "@local/mindtape:0.2.0": *

#show: task.with(
  title: "Track the sparse-lock fix for qahq's flake.lock",
  status: blocked(
    2026,
    10,
    31,
  )[canibump:nix-sparse-lock-files waits on github:NixOS/nix\#7730; \#6124 is the design gap],
)

== Problem

A consumer of qahq copies qahq's whole `flake.lock`. qahq takes each tool as a flake input, so every tool's inputs land in that copy, including inputs only its dev shell uses. Nix has no dev-only inputs (NixOS/nix#6124); sparse lock files (NixOS/nix#7730) would reuse each input's own lock instead of copying its graph, so a consumer records only what it needs.

`flake.nix` now dedupes the duplicate `naersk` and `flake-utils` nodes with `follows`, and `canibump.toml`'s `nix-sparse-lock-files` tracks when #7730 lands. This task keeps that wait visible in the backlog.

== Done when

- `canibump --refresh` says `nix-sparse-lock-files` is `bumpable`.
- The Nix version qahq and its consumers use has sparse lock files.
- This task records that version and closes; `drop-qahqs-follows-map-when-nix-ships-sparse-lock-files` takes over.
