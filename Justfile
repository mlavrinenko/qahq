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
