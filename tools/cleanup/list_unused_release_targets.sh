#!/usr/bin/env bash

# Lists workspace targets which are not needed to build a published artifact or
# to build a test of one of those artifacts (or one of their dependencies).

set -euo pipefail

readonly script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
mapfile -t ROOT_TARGETS < <(sed -e '/^[[:space:]]*#/d' -e '/^[[:space:]]*$/d' "${script_dir}/release_roots.txt")
if ((${#ROOT_TARGETS[@]} == 0)); then
  echo "No roots found in ${script_dir}/release_roots.txt" >&2
  exit 1
fi

usage() {
  cat <<'EOF'
Usage: tools/cleanup/list_unused_release_targets.sh [--label-kind] [-- <bazel query flags>]

Prints one unused Bazel rule target per line. A rule is considered used if it is:
  * a published artifact or explicitly retained tooling target,
  * in the transitive dependency closure of one of those roots,
  * a test that directly depends on anything in that closure, or
  * in the transitive dependency closure of one of those tests.

The analysis is intentionally conservative. Bazel query follows every branch
of configurable attributes (select()), so targets needed by any configuration
are retained.

Options:
  --label-kind  Prefix labels with their Bazel rule kind.
  -h, --help    Show this help.

Arguments following -- are passed to `bazel query`. For example:
  tools/cleanup/list_unused_release_targets.sh -- --color=no
EOF
}

output="label"
declare -a bazel_flags=()
while (($#)); do
  case "$1" in
    --label-kind)
      output="label_kind"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --)
      shift
      bazel_flags=("$@")
      break
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

root_set="set(${ROOT_TARGETS[*]})"

# tests(//...) expands test_suite rules to the test rules they contain. Ordinary
# tests are selected when they directly depend on a production dependency.
# ts_jasmine_node_test macros have six generated-rule edges between the tested
# TypeScript library and the final jasmine_test, so select those at depth 6.
# CLI integration tests use testcli, which runs the published bb binary through
# a coverage-free tool wrapper, so retain direct testcli users explicitly.
# Using unbounded rdeps would select almost every test through shared low-level
# libraries. Keep each selected test's full dependency closure. Test suites are
# deliberately not retained: they are wrappers rather than dependencies needed
# to build or run a test, and repository-wide suites would retain every test.
read -r -d '' query <<EOF || true
let roots = ${root_set} in
let production = deps(\$roots) intersect //... in
let direct_tests = tests(//...) intersect rdeps(//..., \$production, 1) in
let jasmine_tests = kind(jasmine_test, tests(//...) intersect rdeps(//..., \$production, 6)) in
let cli_tests = tests(//...) intersect rdeps(//..., //cli/testutil/testcli:testcli, 1) in
let relevant_tests = \$direct_tests union \$jasmine_tests union \$cli_tests in
kind(".* rule", //...) except deps(\$production union \$relevant_tests)
EOF

if command -v bazelisk >/dev/null 2>&1; then
  bazel_cmd=(bazelisk)
else
  bazel_cmd=(bazel)
fi

exec "${bazel_cmd[@]}" query \
  --noshow_progress \
  --output="$output" \
  "${bazel_flags[@]}" \
  "$query"
