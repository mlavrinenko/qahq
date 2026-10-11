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

    # QA tools re-exported from their own flakes, so a consumer wires only this
    # one input and gets the whole stack pinned together. Each follows qahq's
    # nixpkgs so everything builds against one revision and the cache stays
    # consistent.

    # Third-party.
    # v5.0.15 plus the stdenv.hostPlatform fix, until an upstream tag both
    # carries it and builds (tasks/track-the-jscpd-fork-with-canibump.typ). A
    # current fenix, as upstream's pin uses the deprecated stdenv.isLinux.
    jscpd = {
      url = "github:mlavrinenko/jscpd/v5.0.15-nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        fenix = {
          url = "github:nix-community/fenix";
          inputs.nixpkgs.follows = "nixpkgs";
        };
      };
    };

    # First-party: one input per name in `firstParty` below. Their own qahq
    # input (dev-shell tooling) follows this flake, so the lock holds one qahq
    # instead of a nested copy per tool per release.
    canibump = {
      url = "github:mlavrinenko/canibump";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.qahq.follows = "";
    };
    ejectest = {
      url = "github:mlavrinenko/ejectest";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.qahq.follows = "";
    };
    linecop = {
      url = "github:mlavrinenko/linecop";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    mmz = {
      url = "github:mlavrinenko/mmz";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.qahq.follows = "";
    };
    outdatty = {
      url = "github:mlavrinenko/outdatty";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.qahq.follows = "";
    };
  };

  # Every input is named here, with no `...`: an input missing from this list
  # fails evaluation, and one named but unused fails deadnix in `checks.lint`.
  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      jscpd,
      canibump,
      ejectest,
      linecop,
      mmz,
      outdatty,
    }:
    let
      # Our own tools, each re-exported from its flake. `just bump` and
      # `just changelog` read the names via `lib.firstParty`.
      firstParty = {
        inherit
          canibump
          ejectest
          linecop
          mmz
          outdatty
          ;
      };
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

        tools = thirdParty // builtins.mapAttrs (_: input: input.packages.${system}.default) firstParty;
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

        # Dead code (incl. an unused input, see `outputs`), Nix anti-patterns
        # and formatting drift fail `nix flake check`, so `just check` and CI.
        checks.lint =
          pkgs.runCommand "qahq-lint"
            {
              nativeBuildInputs = [
                pkgs.deadnix
                pkgs.nixfmt
                pkgs.statix
              ];
            }
            ''
              cd ${self}
              deadnix --fail .
              statix check .
              nixfmt --check $(find . -name '*.nix')
              touch $out
            '';

        # `nix develop` here drops the whole stack on PATH, plus the linters
        # behind `checks.lint` for fixing what it reports.
        devShells.default = pkgs.mkShell {
          nativeBuildInputs = builtins.attrValues tools ++ [
            pkgs.deadnix
            pkgs.just
            pkgs.nixfmt
            pkgs.statix
          ];
        };
      }
    )
    // {
      lib.firstParty = builtins.attrNames firstParty;

      # `nixpkgs.overlays = [ qahq.overlays.default ]` then `pkgs.qahq.<tool>`.
      overlays.default = final: _prev: {
        qahq = self.packages.${final.stdenv.hostPlatform.system};
      };
    };
}
