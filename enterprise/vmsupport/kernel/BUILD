load("@io_bazel_rules_go//go:def.bzl", "go_test")
load(":defs.bzl", "microvm_kernel")

package(default_visibility = ["//enterprise:__subpackages__"])

# x86_64 (v6.1) - EXPERIMENTAL (not used in prod yet)
#
# Build and upload with:
#   bazel run //enterprise/vmsupport/kernel:guest_kernel_x86_64_v6_1_upload --config=remote
microvm_kernel(
    name = "guest_kernel_x86_64_v6_1",
    out = "vmlinux-x86_64-v6.1",
    arch = "x86_64",
    config = "microvm-kernel-x86_64-v6.1.config",
    version = "v6.1",
)

go_test(
    name = "kernel_test",
    srcs = ["config_test.go"],
    embedsrcs = [
        "microvm-kernel-aarch64-v5.10.config",
        "microvm-kernel-x86_64-v5.15.config",
        "microvm-kernel-x86_64-v6.1.config",
    ],
)
