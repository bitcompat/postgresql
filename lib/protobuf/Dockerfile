# syntax=docker/dockerfile:1.4
FROM docker.io/bitnami/minideb:bullseye as builder

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN install_packages ca-certificates curl git build-essential g++ cmake tar gzip bzip2 pkg-config

ARG PROTOBUF_CPP_VERSION=3.21.5
ARG PROTOBUF_C_VERSION=1.4.1

RUN mkdir -p /opt/src
ADD --link https://github.com/protobuf-c/protobuf-c/releases/download/v1.4.1/protobuf-c-1.4.1.tar.gz /opt/src/protobuf-c-1.4.1.tar.gz
ADD --link https://github.com/protocolbuffers/protobuf/releases/download/v21.5/protobuf-cpp-3.21.5.tar.gz /opt/src/protobuf-cpp-3.21.5.tar.gz
RUN <<EOT bash
    cd /opt/src
    tar xf protobuf-cpp-${PROTOBUF_CPP_VERSION}.tar.gz
    cd protobuf-${PROTOBUF_CPP_VERSION}

    ./configure --prefix=/opt/bitnami/postgresql
    make -j\$(nproc)
    make install
EOT

RUN <<EOT bash
    cd /opt/src
    tar xf protobuf-c-${PROTOBUF_C_VERSION}.tar.gz
    cd protobuf-c-${PROTOBUF_C_VERSION}

    PKG_CONFIG_PATH=/opt/bitnami/postgresql/lib/pkgconfig:\$PKG_CONFIG_PATH ./configure --prefix=/opt/bitnami/postgresql
    make -j\$(nproc)
    make install
EOT

FROM docker.io/bitnami/minideb:bullseye as stage-0

COPY --link --from=builder /opt/bitnami /opt/bitnami
