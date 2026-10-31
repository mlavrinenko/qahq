{
  description = "qahq — quality-assurance headquarters: shared lint/QA CLI tools, packaged once and re-exported for every consumer flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    # QA tools re-exported from their own flakes, so a consumer wires only this
    # one input and gets the whole stack pinned together. Each follows qahq's
    # nixpkgs so everything builds against one revision and the cache stays
    # consistent.

    # Third-party.
    # v5.4.1 plus the fork's flake fixes and its json `classes`,
    # `--new-only` and `--merge-baseline`, until an upstream tag both carries
    # them and builds (canibump.toml, jscpd-fork). A current fenix, as
    # upstream's pin uses the deprecated stdenv.isLinux.
    # canibump:jscpd-fork
    # canibump:jscpd-fork-classes
    jscpd = {
      url = "github:mlavrinenko/jscpd/v5.4.1-nix.2";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
        fenix = {
          url = "github:nix-community/fenix";
          inputs.nixpkgs.follows = "nixpkgs";
        };
      };
    };

    # First-party: one input per name in `firstParty` below. Their own qahq
    # input (dev-shell tooling) follows this flake, so the lock holds one qahq
    # instead of a nested copy per tool per release.
    #
    # The naersk and flake-utils follows below keep duplicate build inputs out
    # of consumers' locks. Every tool only calls `pkgs.callPackage naersk {}`,
    # and they all pin the same flake-utils. linecop's naersk is the shared one
    # for canibump, ejectest and mindtape; mmz and outdatty keep their newer
    # pins so this does not rebuild five tools for six lock nodes. The anchor is
    # linecop, not mindtape: a consumer that drops qahq's mindtape input to
    # break the qahq cycle would also remove a follows path through it.
    #
    # canibump:nix-sparse-lock-files
    canibump = {
      url = "github:mlavrinenko/canibump";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        qahq.follows = "";
        naersk.follows = "linecop/naersk";
        flake-utils.follows = "flake-utils";
      };
    };
    ejectest = {
      url = "github:mlavrinenko/ejectest";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        qahq.follows = "";
        naersk.follows = "linecop/naersk";
        flake-utils.follows = "flake-utils";
      };
    };
    linecop = {
      url = "github:mlavrinenko/linecop";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        # Pinned to the naersk rev the tools already used, and fenix dropped,
        # so sharing it changes no build. It cannot be mindtape's naersk: a
        # consumer that drops qahq's mindtape input to cut the qahq cycle would
        # remove the follows path. Unpin when the tools share a newer naersk.
        naersk = {
          url = "github:nix-community/naersk/9d4ed44d8b8cecdceb1d6fd76e74123d90ae6339";
          inputs.nixpkgs.follows = "nixpkgs";
          inputs.fenix.follows = "";
        };
        flake-utils.follows = "flake-utils";
      };
    };
    # Its dev shell's inputs sit in a flake-parts partition of their own, so
    # only what builds `mt` reaches this lock.
    mindtape = {
      url = "github:mlavrinenko/mindtape";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        naersk.follows = "linecop/naersk";
      };
    };
    mmz = {
      url = "github:mlavrinenko/mmz";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        qahq.follows = "";
        flake-utils.follows = "flake-utils";
      };
    };
    outdatty = {
      url = "github:mlavrinenko/outdatty";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        qahq.follows = "";
        flake-utils.follows = "flake-utils";
      };
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
      mindtape,
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
          mindtape
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
