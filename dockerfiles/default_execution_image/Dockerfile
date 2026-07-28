FROM ubuntu:16.04

RUN apt-get update && apt-get install -y ca-certificates curl rpm build-essential && apt-get clean && rm -rf /var/lib/apt/lists/*
RUN curl -Lo /usr/local/bin/bazelisk https://github.com/bazelbuild/bazelisk/releases/download/v1.7.4/bazelisk-linux-amd64 && \
  chmod +x /usr/local/bin/bazelisk

# Bazel 8.3.0 or newer requires a newer libc and libstdc++
# and won't be able to run on Ubuntu 16.04
RUN USE_BAZEL_VERSION=8.2.0 /usr/local/bin/bazelisk

# Install docker.
RUN apt-get update && apt-get install -y apt-transport-https software-properties-common && \
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add - && \
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu xenial stable" && \
    apt-get update && apt-get install -y docker-ce && \
    apt-get clean && rm -rf /var/lib/apt/lists/*
