load("@io_bazel_rules_go//go:def.bzl", "go_library", "go_test")

go_library(
    name = "qps",
    srcs = ["qps.go"],
    importpath = "github.com/buildbuddy-io/buildbuddy/server/util/qps",
    visibility = ["//visibility:public"],
    deps = [
        "@com_github_jonboulle_clockwork//:clockwork",
    ],
)
