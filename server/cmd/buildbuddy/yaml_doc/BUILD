load("@io_bazel_rules_go//go:def.bzl", "go_binary", "go_library")

genrule(
    name = "generate_mdx",
    srcs = [":generate_yaml"],
    outs = ["buildbuddy_server_documented_defaults.mdx"],
    cmd = """
        echo "\\`\\`\\`yaml" >> "$@" &&
        cat $(location :generate_yaml) >> "$@" &&
        echo "\\`\\`\\`" >> "$@"
    """,
    visibility = ["//visibility:public"],
)
