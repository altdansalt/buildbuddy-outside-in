load("@io_bazel_rules_go//go:def.bzl", "go_binary", "go_library")

package(default_visibility = ["//enterprise:__subpackages__"])

genrule(
    name = "generate_mdx",
    srcs = [":generate_yaml"],
    outs = ["buildbuddy_executor_documented_defaults.mdx"],
    cmd = """
        echo "\\`\\`\\`yaml" >> "$@" &&
        cat $(location :generate_yaml) >> "$@" &&
        echo "\\`\\`\\`" >> "$@"
    """,
    visibility = [
        "//website:__pkg__",
    ],
)
