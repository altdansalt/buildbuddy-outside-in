load("@io_bazel_rules_docker//container:container.bzl", "container_push")
load("@io_bazel_rules_docker//go:image.bzl", "go_image")
load("@io_bazel_rules_go//go:def.bzl", "go_binary", "go_library")
load("@rules_oci//oci:defs.bzl", "oci_image", "oci_push")
load("@rules_pkg//pkg:tar.bzl", "pkg_tar")

go_library(
    name = "tcpproxy_lib",
    srcs = ["tcpproxy.go"],
    importpath = "github.com/buildbuddy-io/buildbuddy/tools/tcpproxy",
    visibility = ["//visibility:private"],
    deps = ["//server/util/log"],
)

go_image(
    name = "tcpproxy_image",
    base = "@buildbuddy_go_image_base//image",
    binary = ":tcpproxy",
    tags = ["manual"],
    visibility = ["//visibility:public"],
)
