load("@rules_shell//shell:sh_test.bzl", "sh_test")

package(
    default_visibility = ["//visibility:public"],
)

[alias(
    name = t,
    actual = "//server/cmd/buildbuddy:%s" % t,
    tags = ["manual"],
) for t in [
    "base_image",  # container_image
    "buildbuddy_image",  # container_image
]]
