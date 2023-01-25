# syntax=docker/dockerfile:1.4
FROM docker.io/bitnami/minideb:bullseye as builder

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN install_packages ca-certificates curl git build-essential g++ cmake tar gzip bzip2 pkg-config

ARG PROTOBUF_CPP_VERSION=21.12
ARG PROTOBUF_C_VERSION=1.4.1

RUN mkdir -p /opt/src
ADD --link https://github.com/protobuf-c/protobuf-c/releases/download/v${PROTOBUF_C_VERSION}/protobuf-c-${PROTOBUF_C_VERSION}.tar.gz /opt/src/protobuf-c-${PROTOBUF_C_VERSION}.tar.gz
ADD --link https://github.com/protocolbuffers/protobuf/releases/download/v${PROTOBUF_CPP_VERSION}/protobuf-cpp-3.${PROTOBUF_CPP_VERSION}.tar.gz /opt/src/protobuf-cpp-3.${PROTOBUF_CPP_VERSION}.tar.gz
RUN <<EOT bash
    cd /opt/src
    tar xf protobuf-cpp-3.${PROTOBUF_CPP_VERSION}.tar.gz
    cd protobuf-3.${PROTOBUF_CPP_VERSION}

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
