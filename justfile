# The BlueBuild CLI, pinned: a release of the v0.9 line that build.yml's action uses, by digest.
bluebuild := "ghcr.io/blue-build/cli:v0.9.37@sha256:a9a8878a5d1cb40f7b175b2685edb6cc47d979a5995265f9c80b25b714ffe80a"

# The check of a change, on a machine and in checks.yml: the recipe generates a Containerfile.
check: generate

# `bluebuild generate recipes/recipe.yml`, its Containerfile discarded. It writes beside the recipe (.gitignore,
# .bluebuild-scripts_*, .cache), so it runs on a copy of the working tree, uncommitted changes included. It reads the
# base image's OS version from its registry, so it needs the network.
generate:
    #!/usr/bin/env bash
    set -euo pipefail
    tmp=$(mktemp -d)
    trap 'rm -rf "$tmp"' EXIT
    tar -C "{{ justfile_directory() }}" --exclude=./.git -cf - . | tar -C "$tmp" -xf -
    podman run --rm --security-opt label=disable -v "$tmp:/bluebuild" "{{ bluebuild }}" \
      bluebuild generate recipes/recipe.yml > /dev/null
