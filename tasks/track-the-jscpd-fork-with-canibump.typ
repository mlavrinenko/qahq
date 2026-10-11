#import "@local/mindtape:0.2.0": *

#show: task.with(
  title: "Track the jscpd fork with canibump",
  status: done(
    2026,
    10,
    11,
  )[canibump.toml tracks it, with tags v\*.\*.\* since upstream force-pushes a moving v5 tag],
)

== Problem

`flake.nix` pins jscpd to the fork `github:mlavrinenko/jscpd/v5.0.15-nix`, which carries the `stdenv.hostPlatform` fix (d9f932d). Upstream merged it as kucherenko/jscpd#1133 (2026-10-04, `178251b9be`), but no upstream tag works yet:

- v5.4.0 builds, but predates the merge.
- v5.4.1 contains the merge, but fails to build even with jscpd's own `flake.lock`: `pulp-0.22.3` gets `error[E0432]: unresolved import paste::paste` (checked 2026-10-10).

Nothing tells us when the fork can go, so it stays until someone remembers to look.

== Done when

- `canibump.toml` at the repo root, with `#:schema https://raw.githubusercontent.com/mlavrinenko/canibump/main/schema/canibump.schema.json` on its first line (canibump comes from this flake's dev shell), holds this entry:

```toml
[[blocker]]
id = "jscpd-fork"
note = "flake.nix: point jscpd back at github:kucherenko/jscpd and drop the fork, once `nix build github:kucherenko/jscpd/<tag>` succeeds"

# The fix is merged...
[[blocker.all]]
id = "merged"
state = "github:kucherenko/jscpd#1133"

# ...and a release tag carries it.
[[blocker.all]]
id = "released"
reached = "github:kucherenko/jscpd#1133"
in = { tags = "v*" }
```

- `canibump --refresh` reports the entry. It already says `bumpable` because of v5.4.1, which does not build: canibump cannot check "builds". Hence the `note`: with a tag that builds, switch the input, run `just check`, and drop the fork.
- A `just canibump` recipe runs it.
