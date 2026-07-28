load("@io_bazel_rules_go//go:def.bzl", "go_library", "go_test")
load("//:deps.bzl", "PODMAN_VERSION")

package(default_visibility = ["//enterprise:__subpackages__"])

go_library(
    name = "ociregistry",
    srcs = ["ociregistry.go"],
    importpath = "github.com/buildbuddy-io/buildbuddy/enterprise/server/oci/ociregistry",
    visibility = ["//visibility:public"],
    deps = [
        "//enterprise/server/oci/ocicache",
        "//enterprise/server/util/trafficstats",
        "//proto:ociregistry_go_proto",
        "//proto:remote_execution_go_proto",
        "//server/environment",
        "//server/http/httpclient",
        "//server/metrics",
        "//server/real_environment",
        "//server/util/clientip",
        "//server/util/flag",
        "//server/util/log",
        "//server/util/lru",
        "//server/util/prefix",
        "//server/util/status",
        "//third_party/singleflight",
        "@com_github_google_go_containerregistry//pkg/name",
        "@com_github_google_go_containerregistry//pkg/v1:pkg",
        "@com_github_prometheus_client_golang//prometheus",
        "@org_golang_google_genproto_googleapis_bytestream//:bytestream",
    ],
)

# Tell gazelle to make each file a separate test target,
# so the OCI client integration test can keep separate runner properties.
# gazelle:go_test file

go_test(
    name = "ociregistry_test",
    timeout = "short",
    srcs = ["ociregistry_test.go"],
    deps = [
        ":ociregistry",
        "//enterprise/server/clientidentity",
        "//enterprise/server/testutil/testregistry",
        "//server/interfaces",
        "//server/testutil/testcache",
        "//server/testutil/testenv",
        "//server/testutil/testport",
        "//server/util/random",
        "//server/util/testing/flags",
        "@com_github_stretchr_testify//require",
    ],
)
