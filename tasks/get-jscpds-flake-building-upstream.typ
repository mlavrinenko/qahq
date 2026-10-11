#import "@local/mindtape:0.2.0": *

#show: task.with(
  title: "Get jscpd's flake building upstream",
  status: proposed(2026, 10, 11),
)

== Problem

`canibump.toml`'s `jscpd-fork` entry says `bumpable`: v5.4.1 carries kucherenko/jscpd#1133. Yet `nix build github:kucherenko/jscpd/v5.4.1` fails, and so does HEAD (`a4c0bc1`). Upstream CI runs only cargo, which is green, so nothing there builds the flake. Two bugs, both in `flake.nix`:

- `buildDepsOnly` stubs every path crate, including the `[patch.crates-io] paste = { path = "patches/paste" }` stand-in. `pulp` then finds no `paste::paste`.
- The source filter keeps `.html` only under `/templates/`, but the crates embed `page.html`, `README.md`, `frameworks.yaml` and a test `.json` via `include_str!`.

This patch fixes both. `nix build` of HEAD with it succeeds and `jscpd --version` prints 5.4.1 (checked 2026-10-11):

```diff
diff --git a/flake.nix b/flake.nix
index 664e1bd..4d147fa 100644
--- a/flake.nix
+++ b/flake.nix
@@ -34,7 +34,8 @@
           src = ./rust;
           filter = path: type:
             (craneLib.filterCargoSources path type) ||
-            (pkgs.lib.hasSuffix ".html" path && pkgs.lib.hasInfix "/templates/" path);
+            # Files the crates embed with include_str!.
+            builtins.any (ext: pkgs.lib.hasSuffix ext path) [ ".html" ".json" ".md" ".yaml" ];
         };
 
         commonArgs = {
@@ -48,7 +49,17 @@
           ];
         };
 
-        cargoArtifacts = craneLib.buildDepsOnly commonArgs;
+        # buildDepsOnly stubs every path crate, including the [patch] that
+        # stands in for `paste`; keep the real one so dependents still build.
+        dummySrc = craneLib.mkDummySrc {
+          inherit src;
+          extraDummyScript = ''
+            rm -rf $out/patches/paste
+            cp -r --no-preserve=mode ${./rust/patches/paste} $out/patches/paste
+          '';
+        };
+
+        cargoArtifacts = craneLib.buildDepsOnly (commonArgs // { inherit dummySrc; });
 
         jscpd = craneLib.buildPackage (commonArgs // {
           inherit cargoArtifacts;
```

== Done when

- The patch is a PR on kucherenko/jscpd, ideally with a CI job running `nix build`. Posted by the maintainer, not by an agent.
- `canibump.toml`'s `jscpd-fork` entry gains a step on that PR, so it reads `bumpable` only once a tag builds:

```toml
[[blocker.all]]
id = "flake-builds"
reached = "github:kucherenko/jscpd#<pr>"
in = { tags = "v*.*.*" }
```
