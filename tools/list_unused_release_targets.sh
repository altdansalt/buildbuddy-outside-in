#!/usr/bin/env bash

# Lists workspace targets which are not needed to build a published artifact or
# to build a test of one of those artifacts (or one of their dependencies).

set -euo pipefail

readonly ROOT_TARGETS=(
  "//server/cmd/buildbuddy:buildbuddy"
  "//server/cmd/buildbuddy:buildbuddy_image"
  "//enterprise/server/cmd/server:buildbuddy"
  "//enterprise/server/cmd/server:buildbuddy_image"
  "//enterprise/server/cmd/server:image_manifest"
  "//enterprise/server/cmd/executor:executor"
  "//enterprise/server/cmd/executor:executor_linux_amd64_static"
  "//enterprise/server/cmd/executor:executor_image"
  "//enterprise/server/cmd/cache_proxy:cache_proxy_image"
  "//enterprise/server/cmd/cache_proxy:oci_image"
  "//enterprise/deployment:executor_docker_default"
  "//enterprise/deployment:buildbuddy_ci_runner"
  "//cli/cmd/bb:bb"
  "//cli/cmd/bb:bb-darwin-amd64"
  "//cli/cmd/bb:bb-darwin-arm64"
  "//cli/cmd/bb:bb-linux-amd64"
  "//cli/cmd/bb:bb-linux-arm64"
  "//cli/cmd/bb:bb-windows-amd64"
  "//:gazelle"
  "//:buildifier"
  "//cli/explain/compactgraph/testdata:generate"
  "//tools/lint:lint"
  "//tools/fix:fix"
)

usage() {
  cat <<'EOF'
Usage: tools/list_unused_release_targets.sh [--label-kind] [-- <bazel query flags>]

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
  tools/list_unused_release_targets.sh -- --color=no
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

# tests(//...) expands test_suite rules to the test rules they contain. The
# depth-1 rdeps expression then selects tests which directly depend on any
# production artifact dependency. Using unbounded rdeps here would select almost
# every test in the repository through shared low-level libraries. Keep each
# selected test's full dependency closure. Test suites are deliberately not
# retained: they are wrappers around tests rather than dependencies needed to
# build or run a test, and repository-wide suites would retain every test.
read -r -d '' query <<EOF || true
let roots = ${root_set} in
let production = deps(\$roots) in
let relevant_tests = tests(//...) intersect rdeps(//..., \$production, 1) in
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
