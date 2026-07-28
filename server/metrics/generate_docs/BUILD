load("@io_bazel_rules_go//go:def.bzl", "go_binary", "go_library", "go_test")

package(default_visibility = ["//visibility:public"])

genrule(
    name = "generate_mdx",
    srcs = ["//server/metrics:metrics.go"],
    outs = ["docs.mdx"],
    cmd_bash = """
    BAZEL_BINDIR=$(BINDIR) $(location :generate_docs) \
        --prettier_path=$(location //tools/prettier) \
        --input_path=$(SRCS) \
        --output_path=$@
    """,
    tools = [
        ":generate_docs",
        "//tools/prettier",
    ],
    visibility = [
        "//website:__pkg__",
    ],
)
