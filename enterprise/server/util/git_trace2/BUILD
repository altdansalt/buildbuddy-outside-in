load("@io_bazel_rules_go//go:def.bzl", "go_library", "go_test")

package(default_visibility = ["//enterprise:__subpackages__"])

go_test(
    name = "git_trace2_test",
    size = "small",
    srcs = ["git_trace2_test.go"],
    deps = [
        ":git_trace2",
        "//server/testutil/testfs",
        "//server/testutil/testgit",
        "//server/testutil/testshell",
        "@com_github_stretchr_testify//require",
    ],
)
