#!/usr/bin/env bash
# Bump sshush or git-spruce in this NUR repo to the latest published GitHub release.
#
# Usage:
#   ./update.sh sshush|git-spruce|all [--force] [--dry-run]
#
# For each package it fetches the latest release tag and its commit from the
# GitHub API, prefetches the new source hash, rewrites pkgs/<name>/default.nix,
# then discovers the vendorHash from a build failure and rebuilds to verify.

set -euo pipefail

OWNER=bencromwell
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

FORCE=0
DRY_RUN=0
PACKAGES=()

for arg in "$@"; do
  case "$arg" in
    sshush|git-spruce) PACKAGES+=("$arg") ;;
    all) PACKAGES=(sshush git-spruce) ;;
    --force) FORCE=1 ;;
    --dry-run) DRY_RUN=1 ;;
    -h|--help)
      sed -n '2,9p' "${BASH_SOURCE[0]}"
      exit 0
      ;;
    *)
      echo "unknown argument: $arg" >&2
      exit 2
      ;;
  esac
done

if [ "${#PACKAGES[@]}" -eq 0 ]; then
  echo "usage: $0 sshush|git-spruce|all [--force] [--dry-run]" >&2
  exit 2
fi

api() {
  curl -sf "https://api.github.com/repos/$OWNER/$1/$2"
}

json_field() {
  # first value of a top-level-ish "key": "value" pair in pretty-printed JSON
  sed -n 's/.*"'"$1"'": *"\([^"]*\)".*/\1/p' | head -1
}

latest_tag() {
  local repo=$1 tag
  tag=$(api "$repo" "releases/latest" | json_field tag_name || true)
  if [ -z "$tag" ]; then
    # no releases published; fall back to the most recent tag
    tag=$(api "$repo" "tags?per_page=1" | json_field name || true)
  fi
  if [ -z "$tag" ]; then
    echo "could not determine latest tag for $repo" >&2
    return 1
  fi
  echo "$tag"
}

tag_commit() {
  local repo=$1 tag=$2 ref sha type
  ref=$(api "$repo" "git/ref/tags/$tag")
  sha=$(json_field sha <<<"$ref")
  type=$(json_field type <<<"$ref")
  if [ "$type" = "tag" ]; then
    # annotated tag: dereference to the commit
    sha=$(api "$repo" "git/tags/$sha" | json_field sha)
  fi
  echo "$sha"
}

prefetch_src_hash() {
  # nix store prefetch-file prints the hash on stderr, so capture both streams
  local url=$1 out
  if out=$(nix store prefetch-file --unpack "$url" 2>&1); then
    grep -o 'sha256-[A-Za-z0-9+/=]*' <<<"$out" | head -1
  else
    out=$(nix-prefetch-url --unpack "$url")
    nix hash convert --to sri --type sha256 "$out"
  fi
}

current_version() {
  sed -n 's/.*version = "\([^"]*\)".*/\1/p' "$REPO_DIR/pkgs/$1/default.nix" | head -1
}

update_package() {
  local pkg=$1 file="$REPO_DIR/pkgs/$1/default.nix"
  local tag version commit src_hash old_version old_vendor_hash

  tag=$(latest_tag "$pkg")
  version=${tag#v}
  old_version=$(current_version "$pkg")

  echo "==> $pkg: latest release $tag (pinned: ${old_version:-none})"

  if [ "$version" = "$old_version" ] && [ "$FORCE" -eq 0 ]; then
    echo "    already up to date, skipping (use --force to rewrite anyway)"
    return 0
  fi

  commit=$(tag_commit "$pkg" "$tag")
  src_hash=$(prefetch_src_hash "https://github.com/$OWNER/$pkg/archive/$tag.tar.gz")
  if [ -z "$src_hash" ]; then
    echo "    failed to prefetch source hash for $tag" >&2
    return 1
  fi
  old_vendor_hash=$(sed -n 's/.*vendorHash = "\([^"]*\)".*/\1/p' "$file" | head -1)
  echo "    commit: $commit"
  echo "    src hash: $src_hash"

  if [ "$DRY_RUN" -eq 1 ]; then
    echo "    dry run: would set version=$version commit=$commit sha256=$src_hash in $file"
    return 0
  fi

  sed -i \
    -e "s/version = \"[^\"]*\"/version = \"$version\"/" \
    -e "s/commit = \"[^\"]*\"/commit = \"$commit\"/" \
    -e "s/sha256 = \"[^\"]*\"/sha256 = \"$src_hash\"/" \
    -e 's/vendorHash = "[^"]*"/vendorHash = lib.fakeHash/' \
    "$file"

  local vendor_hash build_log
  echo "    discovering vendorHash (expected build failure)..."
  build_log=$(cd "$REPO_DIR" && nix build --no-link ".#$pkg" 2>&1) || true
  # the vendor hash mismatch is reported on the <pkg>-<version>-go-modules derivation
  vendor_hash=$(awk '/go-modules\.drv/ {found=1} found && /got:/ { if (match($0, /sha256-[A-Za-z0-9+/=]*/)) { print substr($0, RSTART, RLENGTH); exit } }' <<<"$build_log")
  if [ -z "$vendor_hash" ]; then
    if grep -q "go-modules" <<<"$build_log" && ! grep -q "hash mismatch" <<<"$build_log"; then
      echo "    build failed for a reason other than the vendor hash:" >&2
      echo "$build_log" >&2
      return 1
    fi
    echo "    no vendorHash change needed (vendor deps unchanged)"
    sed -i "s/vendorHash = lib.fakeHash/vendorHash = \"$old_vendor_hash\"/" "$file"
  else
    echo "    vendorHash: $vendor_hash"
    sed -i "s/vendorHash = lib.fakeHash/vendorHash = \"$vendor_hash\"/" "$file"
  fi

  echo "    verifying build..."
  if ! (cd "$REPO_DIR" && nix build --no-link ".#$pkg"); then
    echo "    verification build failed for $pkg" >&2
    return 1
  fi
  echo "==> $pkg updated to $version"
}

rc=0
for pkg in "${PACKAGES[@]}"; do
  update_package "$pkg" || rc=1
done
exit "$rc"
