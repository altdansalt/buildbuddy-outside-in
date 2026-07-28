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
readonly ordinary_tests_file="$(mktemp)"
readonly enormous_tests_file="$(mktemp)"
trap 'rm -f "$tests_file" "$ordinary_tests_file" "$enormous_tests_file"' EXIT

# Webdriver macros expose private wrapped go_tests which require the public
# web_test rule to provide a browser endpoint. Replace those wrappers with
# their web_test dependents. Jasmine macros put six generated-rule edges between
# the tested TypeScript library and the final test, so include those at depth 6.
# CLI integration tests use testcli to run the published bb binary through a
# coverage-free tool wrapper, so include direct testcli users explicitly. The
# manual linearizability test is intentionally omitted because its long
# Firecracker stress run is not a per-deletion check.
read -r -d '' query <<EOF || true
let production = deps(${selected_roots}) intersect //... in
let direct = tests(//...) intersect rdeps(//..., \$production, 1) in
let jasmine = kind(jasmine_test, tests(//...) intersect rdeps(//..., \$production, 6)) in
let cli = tests(//...) intersect rdeps(//..., //cli/testutil/testcli:testcli, 1) in
let selected = \$direct union \$jasmine union \$cli in
let web = kind(web_test, rdeps(//..., \$selected, 1)) in
((\$selected except attr(name, ".*_wrapped_test", \$selected)) union \$web)
except //enterprise/server/raft/store/linearizability:linearizability_test
EOF

cd "$repo"
"${bazel_cmd[@]}" query --noshow_progress --output=label "$query" >"$tests_file"

test_count="$(wc -l <"$tests_file")"
if ((test_count == 0)); then
  echo "Running 0 tests for ${root_description}"
  exit 0
fi

selected_tests="set($(tr '\n' ' ' <"$tests_file"))"
"${bazel_cmd[@]}" query \
  --noshow_progress \
  --output=label \
  "attr(size, enormous, ${selected_tests})" \
  >"$enormous_tests_file"

sort -o "$tests_file" "$tests_file"
sort -o "$enormous_tests_file" "$enormous_tests_file"
comm -23 "$tests_file" "$enormous_tests_file" >"$ordinary_tests_file"

ordinary_count="$(wc -l <"$ordinary_tests_file")"
enormous_count="$(wc -l <"$enormous_tests_file")"
echo "Running ${test_count} tests for ${root_description}: ${ordinary_count} together, ${enormous_count} enormous tests individually"

test_args=(
  --experimental_output_paths=off
  --skip_incompatible_explicit_targets
  "$@"
)

if ((ordinary_count)); then
  "${bazel_cmd[@]}" test \
    "${test_args[@]}" \
    --target_pattern_file="$ordinary_tests_file"
fi

while IFS= read -r enormous_test; do
  echo "Running enormous test on its own: ${enormous_test}"
  "${bazel_cmd[@]}" test "${test_args[@]}" "$enormous_test"
done <"$enormous_tests_file"
