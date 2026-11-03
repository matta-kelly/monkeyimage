# The BlueBuild CLI, pinned: a release of the v0.9 line that build.yml's action uses, by digest.
bluebuild := "ghcr.io/blue-build/cli:v0.9.37@sha256:a9a8878a5d1cb40f7b175b2685edb6cc47d979a5995265f9c80b25b714ffe80a"

set positional-arguments

root := justfile_directory()

# The check set: scripts/check.sh, on a machine and in checks.yml. It runs only the sets a change touches.
check:
    scripts/check.sh

# Lint the notes, in the Node image.
lint:
    @just _node npm run --silent lint

# The lint runs in this pinned Node image, never on the host, and installs only when the lockfile is newer.
node_image := "docker.io/library/node:22.23.4-slim"

_node +command:
    @podman run --rm --userns=keep-id:uid=1000,gid=1000 --security-opt label=disable --cpus=3 --cpu-shares=256 -u node -e NPM_CONFIG_UPDATE_NOTIFIER=false -v "{{root}}:{{root}}" -w "{{root}}" {{node_image}} sh -c '[ node_modules/.package-lock.json -nt package-lock.json ] || npm ci --ignore-scripts --no-audit --no-fund >/dev/null; '"$*"


# `bluebuild generate recipes/recipe.yml`, its Containerfile discarded. It writes beside the recipe (.gitignore,
# .bluebuild-scripts_*, .cache), so it runs on a copy of the working tree, uncommitted changes included. It reads the
# base image's OS version from its registry, so it needs the network.
generate:
    #!/usr/bin/env bash
    set -euo pipefail
    tmp=$(mktemp -d)
    trap 'rm -rf "$tmp"' EXIT
    tar -C "{{ justfile_directory() }}" --exclude=./.git --exclude=./node_modules -cf - . | tar -C "$tmp" -xf -
    podman run --rm --security-opt label=disable -v "$tmp:/bluebuild" "{{ bluebuild }}" \
      bluebuild generate recipes/recipe.yml > /dev/null
