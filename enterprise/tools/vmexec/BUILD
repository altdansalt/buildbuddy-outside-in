load("@io_bazel_rules_go//go:def.bzl", "go_binary", "go_library")

package(default_visibility = ["//enterprise:__subpackages__"])

go_library(
    name = "vmexec_lib",
    srcs = ["vmexec.go"],
    importpath = "github.com/buildbuddy-io/buildbuddy/enterprise/tools/vmexec",
    visibility = ["//visibility:private"],
    deps = [
        "//enterprise/server/util/vsock",
        "//proto:vmexec_go_proto",
        "//server/util/log",
    ],
)
