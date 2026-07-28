load("@io_bazel_rules_go//go:def.bzl", "go_library", "go_test")

go_library(
    name = "mockgitserver",
    srcs = ["mockgitserver.go"],
    importpath = "github.com/buildbuddy-io/buildbuddy/server/util/mockgitserver",
    visibility = ["//visibility:public"],
    deps = ["//server/util/log"],
)
