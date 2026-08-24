set quiet := true

# List available recipes
default:
    @just --list

# Evaluate flake outputs and compile every tool (the same sequence CI runs)
check:
    nix flake check --print-build-logs
    nix build .#default --print-build-logs

# Build one tool (defaults to the bundle)
build TOOL='default':
    nix build .#{{ TOOL }} --print-build-logs

# Smoke-test a tool binary
run TOOL *ARGS:
    nix run .#{{ TOOL }} -- {{ ARGS }}

# Bump the first-party tool inputs, check, and commit flake.lock
bump: && (_commit-lock "chore: bump tool inputs")
    nix flake update --tarball-ttl 0 ejectest linecop outdatty mmz

# Bump every input (nixpkgs, naersk, ...), check, and commit flake.lock
bump-all: && (_commit-lock "chore: bump flake inputs")
    nix flake update --tarball-ttl 0

# Emit CHANGELOG bullets for first-party tool-input changes vs a git base (default: last release tag)
changelog BASE='':
    #!/usr/bin/env bash
    set -eo pipefail

    BASE="${BASE:-$(git describe --tags --abbrev=0)}"

    rev_at() { # $1 = git ref (or '-' for the worktree lock), $2 = tool
      local ref="$1" tool="$2"
      if [ "$ref" = '-' ]; then
        jq -r --arg t "$tool" '.nodes[.nodes.root.inputs[$t]].locked.rev' flake.lock
      else
        git show "$ref:flake.lock" | jq -r --arg t "$tool" '.nodes[.nodes.root.inputs[$t]].locked.rev'
      fi
    }

    tag_at() { # rev -> its tag name (drops ^{} and the leading sha), or empty if untagged
      local tool="$1" rev="$2"
      git ls-remote --tags "https://github.com/mlavrinenko/$tool.git" 2>/dev/null \
        | awk -v rev="$rev" '$1 == rev { sub("refs/tags/", "", $2); sub(/\^{\}/, "", $2); print $2; exit }'
    }

    hit=0
    for tool in mmz ejectest linecop outdatty; do
      old=$(rev_at "$BASE" "$tool"); new=$(rev_at '-' "$tool")
      [ "$old" = "$new" ] && continue
      ot=$(tag_at "$tool" "$old"); nt=$(tag_at "$tool" "$new")
      [ -n "$ot" ] && ot=" [$ot]"; [ -n "$nt" ] && nt=" [$nt]"
      printf -- '- %s: %s%s -> %s%s\n' "$tool" "${old:0:9}" "$ot" "${new:0:9}" "$nt"
      hit=1
    done
    if [ "$hit" = 0 ]; then
      echo "no first-party tool-input changes since $BASE"
    fi

[private]
_commit-lock MESSAGE:
    just check
    git add flake.lock
    git diff --cached --quiet flake.lock && echo "flake.lock already up to date" || git commit -m "{{ MESSAGE }}"
