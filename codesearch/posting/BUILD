load("@io_bazel_rules_go//go:def.bzl", "go_library", "go_test")

go_library(
    name = "posting",
    srcs = ["posting.go"],
    importpath = "github.com/buildbuddy-io/buildbuddy/codesearch/posting",
    visibility = ["//visibility:public"],
    deps = ["@com_github_roaringbitmap_roaring//roaring64"],
)
