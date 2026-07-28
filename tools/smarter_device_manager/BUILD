load("@io_bazel_rules_docker//container:container.bzl", "container_push")
load("@io_bazel_rules_docker//go:image.bzl", "go_image")
load("@rules_oci//oci:defs.bzl", "oci_image", "oci_push")
load("@rules_pkg//pkg:tar.bzl", "pkg_tar")

go_image(
    name = "smarter_device_manager_image",
    base = "@buildbuddy_go_image_base//image",
    binary = ":smarter-device-manager",
    tags = ["manual"],
    visibility = ["//visibility:public"],
)

pkg_tar(
    name = "tar",
    srcs = [":smarter-device-manager"],
)
