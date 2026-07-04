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
    jscpd = {
      url = "github:kucherenko/jscpd/v5.0.11";
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
    outdatty = {
      url = "github:mlavrinenko/outdatty";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    mmz = {
      url = "github:mlavrinenko/mmz";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      naersk,
      jscpd,
      ejectest,
      linecop,
      outdatty,
      mmz,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = (import nixpkgs) { inherit system; };
        naersk' = pkgs.callPackage naersk { };

        # Crate with no upstream flake, vendored from crates.io.
        cargo-crap = pkgs.callPackage ./pkgs/cargo-crap.nix { };

        # Tools consumed from their own flakes. Each follows qahq's nixpkgs
        # (see inputs) so the whole closure stays on one revision.
        flakeTools = {
          jscpd = jscpd.packages.${system}.default;
          ejectest = ejectest.packages.${system}.default;
          linecop = linecop.packages.${system}.default;
          outdatty = outdatty.packages.${system}.default;
          mmz = mmz.packages.${system}.default;
        };

        tools = { inherit cargo-crap; } // flakeTools;
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
      # `nixpkgs.overlays = [ qahq.overlays.default ]` then `pkgs.qahq.<tool>`.
      overlays.default = final: _prev: {
        qahq = self.packages.${final.stdenv.hostPlatform.system};
      };
    };
}
