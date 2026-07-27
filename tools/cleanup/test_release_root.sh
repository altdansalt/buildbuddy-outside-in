#!/usr/bin/env bash

# Finds and runs tests which directly test a release root or anything in its
# transitive dependency closure.

set -euo pipefail

readonly script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly repo="$(cd "${script_dir}/../.." && pwd)"
readonly roots_file="${script_dir}/release_roots.txt"

usage() {
  cat <<'EOF'
Usage: tools/cleanup/test_release_root.sh TARGET [-- <bazel test flags>]
       tools/cleanup/test_release_root.sh --all [-- <bazel test flags>]

Enumerates tests which directly depend on TARGET or anything in TARGET's
transitive dependency closure, then runs them. TARGET must be listed in
tools/cleanup/release_roots.txt.

With --all, runs the union of tests selected by every configured root.
EOF
}

if (($# == 0)) || [[ "$1" == "-h" || "$1" == "--help" ]]; then
  usage
  exit $(( $# == 0 ? 2 : 0 ))
fi

readonly root="$1"
shift
if (($#)) && [[ "$1" == "--" ]]; then
  shift
fi

mapfile -t configured_roots < <(sed -e '/^[[:space:]]*#/d' -e '/^[[:space:]]*$/d' "$roots_file")
if [[ "$root" == "--all" ]]; then
  selected_roots="set(${configured_roots[*]})"
  root_description="all configured roots"
else
  if ! printf '%s\n' "${configured_roots[@]}" | grep -Fxq -- "$root"; then
    echo "Not a configured release root: $root" >&2
    exit 2
  fi
  selected_roots="$root"
  root_description="$root"
fi

if command -v bazelisk >/dev/null 2>&1; then
  bazel_cmd=(bazelisk)
else
  bazel_cmd=(bazel)
fi

readonly tests_file="$(mktemp)"
trap 'rm -f "$tests_file"' EXIT

read -r -d '' query <<EOF || true
let production = deps(${selected_roots}) intersect //... in
tests(//...) intersect rdeps(//..., \$production, 1)
EOF

cd "$repo"
"${bazel_cmd[@]}" query --noshow_progress --output=label "$query" >"$tests_file"

test_count="$(wc -l <"$tests_file")"
echo "Running ${test_count} tests for ${root_description}"
if ((test_count == 0)); then
  exit 0
fi

exec "${bazel_cmd[@]}" test \
  --experimental_output_paths=off \
  --skip_incompatible_explicit_targets \
  "$@" \
  --target_pattern_file="$tests_file"
