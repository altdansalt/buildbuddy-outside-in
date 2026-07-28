load("@rules_python//python:defs.bzl", "py_binary", "py_library")
load("@rules_shell//shell:sh_test.bzl", "sh_test")

# gazelle:exclude example_plugins/**/*.py
# gazelle:exclude plugins/**/*.py
# gazelle:default_visibility //cli:__subpackages__
package(default_visibility = ["//cli:__subpackages__"])

exports_files(
    srcs = ["install.sh"],
)
