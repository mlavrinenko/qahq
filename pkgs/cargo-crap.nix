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
  version = "0.2.2";

  src = fetchCrate {
    inherit pname version;
    hash = "sha256-cZ30mdHHLXzpvMhkC6XoPMgfqAdsmdqhEfHq8T15Fmw=";
  };

  cargoHash = "sha256-vzkGNzQrVOtfpGLniGTdPRQfwA9jn5elXhudrFC7w9g=";

  # Dev/CI tool: skip its own test suite to keep the build lean.
  doCheck = false;

  meta = {
    description = "Cargo subcommand that gates functions by the CRAP change-risk metric";
    homepage = "https://github.com/minikin/cargo-crap";
    license = lib.licenses.mit;
    mainProgram = "cargo-crap";
  };
}
