load("@io_bazel_rules_go//go:def.bzl", "go_binary", "go_library", "go_test")

package(default_visibility = ["//visibility:public"])

go_test(
    name = "generate_docs_test",
    srcs = ["generate_docs_test.go"],
    embed = [":generate_docs_lib"],
    deps = [
        "@com_github_stretchr_testify//assert",
        "@com_github_stretchr_testify//require",
    ],
)

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
