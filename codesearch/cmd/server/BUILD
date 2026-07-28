load("@io_bazel_rules_docker//container:container.bzl", "container_push")
load("@io_bazel_rules_docker//go:image.bzl", "go_image")
load("@io_bazel_rules_go//go:def.bzl", "go_binary", "go_library")
load("@rules_oci//oci:defs.bzl", "oci_image", "oci_push")
load("@rules_pkg//pkg:tar.bzl", "pkg_tar")

go_library(
    name = "server_lib",
    srcs = ["server.go"],
    importpath = "github.com/buildbuddy-io/buildbuddy/codesearch/cmd/server",
    visibility = ["//visibility:private"],
    deps = [
        "//codesearch/server",
        "//enterprise/server/backends/configsecrets",
        "//enterprise/server/clientidentity",
        "//enterprise/server/remoteauth",
        "//proto:codesearch_service_go_proto",
        "//server/config",
        "//server/real_environment",
        "//server/rpc/interceptors",
        "//server/util/authutil",
        "//server/util/flag",
        "//server/util/grpc_client",
        "//server/util/grpc_server",
        "//server/util/healthcheck",
        "//server/util/log",
        "//server/util/monitoring",
        "@org_golang_google_genproto_googleapis_bytestream//:bytestream",
        "@org_golang_google_grpc//:grpc",
    ],
)

pkg_tar(
    name = "tar",
    srcs = [":server"],
)
