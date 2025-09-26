# syntax=docker/dockerfile:1.18
FROM docker.io/bitnami/minideb:bookworm AS builder

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN install_packages ca-certificates curl git build-essential g++ cmake tar gzip bzip2 pkg-config \
    libsqlite3-dev libreadline-dev sqlite3

ARG UNIX_ODBC_VERSION=2.3.12

ADD --link https://github.com/lurcher/unixODBC/releases/download/${UNIX_ODBC_VERSION}/unixODBC-${UNIX_ODBC_VERSION}.tar.gz /opt/src/unixODBC-${UNIX_ODBC_VERSION}.tar.gz

RUN mkdir -p /opt/src
RUN <<EOT bash
    set -eu

    cd /opt/src
    tar xf unixODBC-${UNIX_ODBC_VERSION}.tar.gz
    cd unixODBC-${UNIX_ODBC_VERSION}
    ./configure --prefix=/opt/bitnami/common --with-pic
    make -j\$(nproc)
    make install

    mkdir -p /opt/bitnami/common/licenses
    cp COPYING /opt/bitnami/common/licenses/unixodbc-${UNIX_ODBC_VERSION}.txt
EOT

FROM docker.io/bitnami/minideb:bookworm AS stage-0

COPY --link --from=builder /opt/bitnami /opt/bitnami
