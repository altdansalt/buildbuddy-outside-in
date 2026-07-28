load("@io_bazel_rules_docker//container:container.bzl", "container_image", "container_push")
load("@rules_oci//oci:defs.bzl", "oci_image", "oci_push")
load("@rules_pkg//pkg:tar.bzl", "pkg_tar")

container_push(
    name = "push_probers_image",
    format = "Docker",
    image = ":probers_image",
    registry = "gcr.io",
    repository = "flame-build/probers",  # Note flame-build, not flame-public.
    # Set the image tag with the bazel run flag "--//deployment:image_tag=TAG"
    tag_file = "//deployment:image_tag_file",
    tags = ["manual"],  # Don't include this target in wildcard patterns
)

oci_push(
    name = "push_probers_oci_image",
    image = ":probers_oci_image",
    remote_tags = "//deployment:oci_tag.txt",
    repository = "gcr.io/flame-build/probers-oci",
)
