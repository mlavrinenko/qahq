set quiet := true

# List available recipes
default:
    @just --list

# Evaluate and build every tool, the bundle, and the devShell
check:
    nix flake check --print-build-logs

# Build one tool (defaults to the bundle)
build TOOL='default':
    nix build .#{{ TOOL }} --print-build-logs

# Smoke-test a tool binary
run TOOL *ARGS:
    nix run .#{{ TOOL }} -- {{ ARGS }}

# Bump the first-party tool inputs, check, and commit flake.lock
bump: && (_commit-lock "chore: bump tool inputs")
    nix flake update ejectest linecop outdatty mmz

# Bump every input (nixpkgs, naersk, ...), check, and commit flake.lock
bump-all: && (_commit-lock "chore: bump flake inputs")
    nix flake update

[private]
_commit-lock MESSAGE:
    just check
    git add flake.lock
    git diff --cached --quiet flake.lock && echo "flake.lock already up to date" || git commit -m "{{ MESSAGE }}"
