{
  description = "qahq — quality-assurance headquarters: shared lint/QA CLI tools, packaged once and re-exported for every consumer flake";

  # Binary cache. Consumers that do NOT override qahq's nixpkgs pin pull prebuilt
  # binaries instead of compiling cargo-crap/jscpd (and the first-party tools)
  # from source.

  nixConfig = {
    extra-substituters = [ "https://qahq.cachix.org" ];
    extra-trusted-public-keys = [ "qahq.cachix.org-1:m43yxxOk1vih9jTZmKXZXgHSSKsW/rNVZUqgXqrELM8=" ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    naersk = {
      url = "github:nix-community/naersk";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # QA tools re-exported from their own flakes, so a consumer wires only this
    # one input and gets the whole stack pinned together. Each follows qahq's
    # nixpkgs so everything builds against one revision and the cache stays
    # consistent.

    # Third-party.
    # v5.0.15 plus the stdenv.hostPlatform fix, until it lands upstream. A
    # current fenix, as upstream's pin uses the deprecated stdenv.isLinux.
    jscpd = {
      url = "github:mlavrinenko/jscpd/v5.0.15-nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.fenix.follows = "fenix";
    };
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # First-party: one input per name in `firstParty` below.
    canibump = {
      url = "github:mlavrinenko/canibump";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    ejectest = {
      url = "github:mlavrinenko/ejectest";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    linecop = {
      url = "github:mlavrinenko/linecop";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    mmz = {
      url = "github:mlavrinenko/mmz";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    outdatty = {
      url = "github:mlavrinenko/outdatty";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      jscpd,
      ...
    }@inputs:
    let
      # Our own tools, each re-exported from the flake input of the same name.
      # `just bump` and `just changelog` read this list via `lib.firstParty`.
      firstParty = [
        "canibump"
        "ejectest"
        "linecop"
        "mmz"
        "outdatty"
      ];
    in
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = (import nixpkgs) { inherit system; };

        # Someone else's tools: vendored in pkgs/ from crates.io when there is
        # no upstream flake, else consumed from it.
        thirdParty = {
          cargo-crap = pkgs.callPackage ./pkgs/cargo-crap.nix { };
          jscpd = jscpd.packages.${system}.default;
        };

        tools =
          thirdParty
          // nixpkgs.lib.genAttrs firstParty (name: inputs.${name}.packages.${system}.default);
      in
      {
        # Every tool individually (`nix build .#jscpd`, `nix run .#cargo-crap`)
        # plus `default`: one derivation with all tools on PATH, for a consumer
        # devShell that wants the whole stack in a single entry.
        packages = tools // {
          default = pkgs.buildEnv {
            name = "qahq";
            paths = builtins.attrValues tools;
          };
        };

        # `nix develop` here drops the whole stack on PATH.
        devShells.default = pkgs.mkShell {
          nativeBuildInputs = builtins.attrValues tools ++ [ pkgs.just ];
        };
      }
    )
    // {
      lib = { inherit firstParty; };

      # `nixpkgs.overlays = [ qahq.overlays.default ]` then `pkgs.qahq.<tool>`.
      overlays.default = final: _prev: {
        qahq = self.packages.${final.stdenv.hostPlatform.system};
      };
    };
}
