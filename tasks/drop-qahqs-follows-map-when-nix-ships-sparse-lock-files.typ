#import "@local/mindtape:0.2.0": *

#show: task.with(
  title: "Drop qahq's follows map when Nix ships sparse lock files",
  status: blocked(
    2026,
    10,
    31,
  )[blocked by track-the-sparse-lock-fix-for-qahqs-flake-lock],
  links: depends-on("track-the-sparse-lock-fix-for-qahqs-flake-lock.typ"),
)

== Problem

`flake.nix`'s `follows` map exists only to keep duplicate `naersk` and `flake-utils` nodes out of consumers' locks. It also forces canibump, ejectest and linecop onto mindtape's `naersk` pin, so their own pins no longer decide the build helper. Sparse lock files make the map unnecessary for lock size; each tool's pin can stand again.

== Done when

- `track-the-sparse-lock-fix-for-qahqs-flake-lock` is done and the pinned Nix has sparse lock files.
- Remove the `canibump:nix-sparse-lock-files` marker, the `naersk`/`flake-utils` follows, and the `nix-sparse-lock-files` blocker; run `nix flake lock`.
- A fresh consumer lock no longer grows with qahq's transitive inputs, and `just check` is green.
