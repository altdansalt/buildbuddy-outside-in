load("@io_bazel_rules_go//go:def.bzl", "go_binary", "go_library")

package(default_visibility = ["//enterprise:__subpackages__"])

genrule(
    name = "generate_mdx",
    outs = ["docs.mdx"],
    cmd_bash = """
    ./$(location :generate_docs) -output_path="$@"
    """,
    tools = [
        ":generate_docs",
    ],
    visibility = [
        "//website:__pkg__",
    ],
)
