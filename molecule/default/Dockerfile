FROM docker.io/library/ubuntu:24.04

# Minimal toolchain to bootstrap Ansible. The macos role is gated on
# ansible_os_family == 'Darwin' and is skipped at converge time, so no
# Darwin-specific packages are needed in this image — its only purpose is
# to satisfy molecule's requirement of a real container target.
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        python3 python3-apt sudo openssh-server ca-certificates \
    && rm -rf /var/lib/apt/lists/*
