load("@rules_python//python:defs.bzl", "py_binary", "py_library")

exports_files(["process_dashboard.py"])

py_binary(
    name = "simulate_traffic",
    srcs = ["simulate_traffic.py"],
    visibility = ["//:__subpackages__"],
)
