# jscpd: Rust copy/paste detector from crates.io (not the npm tool of the same
# name). Not in nixpkgs. naersk vendors through cargo itself — nixpkgs'
# fetch-cargo-vendor is UA-blocked by crates.io's data-access policy — and
# `singleStep` skips naersk's dummy-src deps build, which fails to parse this
# crate's manifest.
{
  lib,
  fetchCrate,
  naersk,
}:
let
  pname = "jscpd";
  version = "5.0.5";
in
(naersk.buildPackage {
  src = fetchCrate {
    inherit pname version;
    hash = "sha256-U0unnpWU8gxudX+YVuvE+uBk6hkNWiMjJxXDBAGzqiA=";
  };
  singleStep = true;
}).overrideAttrs
  (old: {
    # naersk already names this jscpd-5.0.5; only attach richer meta.
    meta = (old.meta or { }) // {
      description = "Fast copy/paste detector (Rust build of jscpd)";
      homepage = "https://crates.io/crates/jscpd";
      license = lib.licenses.mit;
      mainProgram = "jscpd";
    };
  })
