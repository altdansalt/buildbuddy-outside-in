load("@io_bazel_rules_go//go:def.bzl", "go_binary", "go_library")

go_library(
    name = "agent_review_lib",
    srcs = ["main.go"],
    embedsrcs = ["settings.json"],
    importpath = "github.com/buildbuddy-io/buildbuddy/enterprise/tools/agent_review",
    visibility = ["//visibility:private"],
    deps = [
        "//server/util/log",
        "@com_github_google_go_github_v59//github",
    ],
)

package(default_visibility = ["//enterprise:__subpackages__"])
