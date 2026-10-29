# cargo-crap: CRAP-metric gate for Cargo projects. Not in nixpkgs yet, so build
# the published crate straight from crates.io. Portable callPackage derivation —
# liftable verbatim into nixpkgs if/when it gets upstreamed.
{
  lib,
  rustPlatform,
  fetchCrate,
}:
rustPlatform.buildRustPackage rec {
  pname = "cargo-crap";
  version = "0.3.1";

  src = fetchCrate {
    inherit pname version;
    hash = "sha256-3qvyS5+7kQgmfk8Sl+29VJq+u+aECoh6n9A/9i0fRyY=";
  };

  cargoHash = "sha256-wajI7ex7t8nOvMMBVL16LOzZJiwc0IGd6D+fYmTXXGo=";

  # Dev/CI tool: skip its own test suite to keep the build lean.
  doCheck = false;

  meta = {
    description = "Cargo subcommand that gates functions by the CRAP change-risk metric";
    homepage = "https://github.com/minikin/cargo-crap";
    license = lib.licenses.mit;
    mainProgram = "cargo-crap";
  };
}
