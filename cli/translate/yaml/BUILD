load("@io_bazel_rules_go//go:def.bzl", "go_library", "go_test")

package(default_visibility = ["//cli:__subpackages__"])

go_test(
    name = "yaml_test",
    srcs = ["yaml_test.go"],
    embed = [":yaml"],
    deps = ["@com_github_stretchr_testify//assert"],
)
