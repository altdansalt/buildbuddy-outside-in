load("@io_bazel_rules_docker//container:container.bzl", "container_image", "container_push")
load("@rules_oci//oci:defs.bzl", "oci_image", "oci_push")
load("@rules_pkg//pkg:tar.bzl", "pkg_tar")

oci_push(
    name = "push_probers_oci_image",
    image = ":probers_oci_image",
    remote_tags = "//deployment:oci_tag.txt",
    repository = "gcr.io/flame-build/probers-oci",
)
