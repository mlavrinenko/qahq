#import "@local/mindtape:0.2.0": *

#show: task.with(
  title: "Get jscpd's flake building upstream",
  status: proposed(2026, 10, 11),
)

== Problem

`canibump.toml`'s `jscpd-fork` entry says `bumpable`: v5.4.1 carries kucherenko/jscpd#1133. Yet `nix build github:kucherenko/jscpd/v5.4.1` fails, and so does HEAD (`a4c0bc1`). Upstream CI runs only cargo, which is green, so nothing there builds the flake. No upstream issue or PR covers it (checked 2026-10-11). Two bugs, both in `flake.nix`, one branch each on github:mlavrinenko/jscpd, cut from upstream `a4c0bc1`:

- `fix/nix-patched-paste-crate` (`8d41ae0`): `buildDepsOnly` stubs every path crate, including the `[patch.crates-io] paste = { path = "patches/paste" }` stand-in from `e66eb72` (first in v5.3.3). `pulp` then finds no `paste::paste`.
- `fix/nix-embedded-files` (`6104323`): the source filter keeps `.html` only under `/templates/`, but the crates embed `page.html`, `README.md` and `frameworks.yaml` (since `e9e46e3`) via `include_str!`.

Each branch alone still fails, at the other bug. Merged together, `nix build` and `nix flake check` pass, and `jscpd --version` prints 5.4.1 (checked 2026-10-11).

== Done when

- Both branches are PRs on kucherenko/jscpd. Posted by the maintainer, not by an agent.
- `canibump.toml`'s `jscpd-fork` entry gains a step per PR, so it reads `bumpable` only once a tag carries both:

```toml
[[blocker.all]]
id = "paste-crate-fixed"
reached = "github:kucherenko/jscpd#<pr>"
in = { tags = "v*.*.*" }

[[blocker.all]]
id = "embedded-files-fixed"
reached = "github:kucherenko/jscpd#<pr>"
in = { tags = "v*.*.*" }
```
