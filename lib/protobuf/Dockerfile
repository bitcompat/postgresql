# syntax=docker/dockerfile:1.17
FROM docker.io/bitnami/minideb:bookworm AS builder

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN install_packages ca-certificates curl git build-essential g++ cmake tar gzip bzip2 pkg-config cmake

ARG PROTOBUF_CPP_VERSION=32.0
ARG PROTOBUF_C_VERSION=1.5.2

RUN mkdir -p /opt/src
ADD --link https://github.com/protobuf-c/protobuf-c/releases/download/v${PROTOBUF_C_VERSION}/protobuf-c-${PROTOBUF_C_VERSION}.tar.gz /opt/src/protobuf-c-${PROTOBUF_C_VERSION}.tar.gz

RUN <<EOT bash
    set -e
    install_packages zlib1g-dev

    cd /opt/src
    git clone --depth 1 -b v${PROTOBUF_CPP_VERSION} https://github.com/protocolbuffers/protobuf.git protobuf-${PROTOBUF_CPP_VERSION}
    cd protobuf-${PROTOBUF_CPP_VERSION}
    git submodule update --init --recursive

    mkdir build
    cd build
    cmake -DCMAKE_INSTALL_PREFIX=/opt/bitnami/common -Dprotobuf_BUILD_TESTS=OFF -DBUILD_SHARED_LIBS=OFF ..
    cmake --build .
    cmake --install .

    mkdir -p /opt/bitnami/common/licenses
    cp ../LICENSE /opt/bitnami/common/licenses/protobuf-${PROTOBUF_CPP_VERSION}.txt
EOT

RUN <<EOT bash
    cd /opt/src
    tar xf protobuf-c-${PROTOBUF_C_VERSION}.tar.gz
    cd protobuf-c-${PROTOBUF_C_VERSION}

    PKG_CONFIG_PATH=/opt/bitnami/common/lib/pkgconfig:\$PKG_CONFIG_PATH ./configure --prefix=/opt/bitnami/common
    make -j\$(nproc)
    make install

    mkdir -p /opt/bitnami/common/licenses
    cp LICENSE /opt/bitnami/common/licenses/protobuf-c-${PROTOBUF_C_VERSION}.txt
EOT

FROM docker.io/bitnami/minideb:bookworm AS stage-0

COPY --link --from=builder /opt/bitnami /opt/bitnami
