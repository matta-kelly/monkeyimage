#!/usr/bin/env bash
# The check set of this repo. `just check` and the pipeline both run this file, so green means the same in both places.
#
#   scripts/check.sh          the sets the change touched. On main in the pipeline, every set
#   scripts/check.sh all      every set
#   scripts/check.sh <set>    one set
#   scripts/check.sh --plan   print the sets the change needs, and run none
#
# The three parts below are monkeyimage's. The rest is the template's (kinetic, templates/repo).
set -euo pipefail
cd "$(dirname "$0")/.."

# 1. The sets, cheapest first. The first failure ends the run.
sets="lint units generate"

# 2. Each set's commands.
# The lint where Node is: the pipeline's, or else the Node image (the justfile). generate: the recipe makes a Containerfile.
set_lint() { if command -v npm >/dev/null; then npm run --silent lint; else just lint; fi; }
set_generate() { just generate; }

# units: each unit the recipe's systemd module enables has a file. Ours are the committed files in files/system, so a
# unit left uncommitted fails here, as it does in the build. The rest come from the base image, a package or a stage,
# and are named in from_elsewhere with their source. A new one of those is added there.
from_elsewhere="rpm-ostreed-automatic.timer kanshi.service tailscaled.service keyd.service monke-model.service" # base, base, tailscale, keyd stage, monke stage
set_units() {
  local scope unit missing=0
  while read -r scope unit; do
    case " $from_elsewhere " in *" $unit "*) continue ;; esac
    [ -n "$(git ls-files "files/system/usr/lib/systemd/$scope/$unit")" ] && continue
    echo "units: the recipe enables the $scope unit $unit, but files/system/usr/lib/systemd/$scope/ has no committed file of it" >&2
    missing=1
  done < <(awk '/type: systemd/{on=1} /type: signing/{on=0} on && /^ +system:/{scope="system"} on && /^ +user:/{scope="user"} on && /^ *- [^ ]+\.(service|timer)/{print scope, $2}' recipes/recipe.yml)
  return "$missing"
}

# 3. The sets a changed file needs. A file no rule names needs every set, so a missing rule runs more, never less.
sets_for() {
  case "$1" in
    *.md) echo lint ;;
    files/* | recipes/*) echo units generate ;;
    *) echo all ;;
  esac
}

# The files the change touched against the base: each commit since it left it, what is not committed yet, and what is
# not tracked yet. A renamed file counts at both of its paths.
changed() {
  local from
  from=$(git merge-base "${CHECK_BASE:-origin/main}" HEAD) || return 1
  git diff --name-only --no-renames "$from" || return 1
  git ls-files --others --exclude-standard
}

# Every set, when it cannot tell what changed, when nothing did, or on main in the pipeline: the full run that catches
# what a skip missed.
plan() {
  local files file need=""
  if [ "${GITHUB_REF:-}" = refs/heads/main ] || ! files=$(changed 2>/dev/null) || [ -z "$files" ]; then
    echo "$sets"
    return
  fi
  while IFS= read -r file; do
    need="$need $(sets_for "$file")"
  done <<<"$files"
  case " $need " in
    *" all "*)
      echo "$sets"
      return
      ;;
  esac
  local set out=""
  for set in $sets; do
    case " $need " in *" $set "*) out="$out $set" ;; esac
  done
  echo "${out# }"
}

# Packages, from the lockfile and frozen, when they are not current.
install() {
  command -v npm >/dev/null || return 0
  [ ! -e package-lock.json ] || [ node_modules/.package-lock.json -nt package-lock.json ] || npm ci
}

case "${1:-}" in
  "") todo=$(plan) ;;
  all) todo=$sets ;;
  --plan)
    plan
    exit 0
    ;;
  *)
    case " $sets " in
      *" $1 "*) todo=$1 ;;
      *)
        echo "usage: scripts/check.sh [all|--plan|$(echo "$sets" | tr ' ' '|')]" >&2
        exit 2
        ;;
    esac
    ;;
esac

install
for set in $todo; do
  echo "== $set"
  "set_$set" || {
    echo "check failed at: $set" >&2
    exit 1
  }
done
echo "check passed"
