#import "@local/mindtape:0.2.0": *

#show: task.with(
  title: "Get jscpd's flake building upstream",
  status: proposed(2026, 10, 11),
)

== Problem

`canibump.toml`'s `jscpd-fork` entry says `bumpable`: v5.4.1 carries kucherenko/jscpd#1133. Yet `nix build github:kucherenko/jscpd/v5.4.1` fails, and so does HEAD (`a4c0bc1`). Upstream CI runs only cargo, which is green, so nothing there builds the flake. No upstream issue or PR covers it (checked 2026-10-11).

Branch `fix/nix-build` on github:mlavrinenko/jscpd, cut from upstream `a4c0bc1`, fixes it with one commit per cause, both in `flake.nix`:

- `36e23b3`: `buildDepsOnly` stubs every path crate, including the `[patch.crates-io] paste = { path = "patches/paste" }` stand-in from `e66eb72` (first in v5.3.3). `pulp` then finds no `paste::paste`.
- `fcf0c30`: the source filter keeps `.html` only under `/templates/`, but the crates embed `page.html`, `README.md` and `frameworks.yaml` (since `e9e46e3`) via `include_str!`.

With both, `nix build` and `nix flake check` pass and `jscpd --version` prints 5.4.1 (checked 2026-10-11). One PR, not two: neither commit alone makes `nix build` pass.

== Done when

- `fix/nix-build` is a PR on kucherenko/jscpd. Posted by the maintainer, not by an agent.
- `canibump.toml`'s `jscpd-fork` entry gains a step on that PR, so it reads `bumpable` only once a tag carries the fix:

```toml
[[blocker.all]]
id = "flake-builds"
reached = "github:kucherenko/jscpd#<pr>"
in = { tags = "v*.*.*" }
```
