load("@io_bazel_rules_go//go:def.bzl", "go_test")
load(":defs.bzl", "microvm_kernel")

package(default_visibility = ["//enterprise:__subpackages__"])

go_test(
    name = "kernel_test",
    srcs = ["config_test.go"],
    embedsrcs = [
        "microvm-kernel-aarch64-v5.10.config",
        "microvm-kernel-x86_64-v5.15.config",
        "microvm-kernel-x86_64-v6.1.config",
    ],
)
