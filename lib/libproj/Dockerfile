# syntax=docker/dockerfile:1.18
ARG RUN_TESTS=0

FROM docker.io/bitnami/minideb:bookworm AS builder

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN install_packages ca-certificates curl git build-essential g++ cmake tar gzip bzip2 pkg-config \
    libsqlite3-dev libtiff-dev libcurl4-gnutls-dev python3 sqlite3 python3-lib2to3

ARG RUN_TESTS
ARG PROJ_VERSION=8.2.1

ADD --link https://download.osgeo.org/proj/proj-${PROJ_VERSION}.tar.gz /opt/src/proj-${PROJ_VERSION}.tar.gz

RUN mkdir -p /opt/src
RUN <<EOT bash
    set -eu
    mkdir -p /opt/bitnami/postgresql

    cd /opt/src
    tar xf proj-${PROJ_VERSION}.tar.gz
    cd proj-${PROJ_VERSION}
    mkdir build

    BUILD_TESTING=OFF
    if [[ "${RUN_TESTS}" != "0" ]]; then
      BUILD_TESTING=ON
    fi

    cd build
    cmake .. -DBUILD_APPS=ON -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/opt/bitnami/postgresql -DBUILD_TESTING=\$BUILD_TESTING
    cmake --build . -j\$(nproc)

    if [[ "${RUN_TESTS}" != "0" ]]; then
      ctest
    fi
    cmake --build . --target install
    mkdir -p /opt/bitnami/postgresql/licenses
    cp ../COPYING /opt/bitnami/postgresql/licenses/proj-${PROJ_VERSION}.txt
EOT

FROM docker.io/bitnami/minideb:bookworm AS stage-0

COPY --link --from=builder /opt/bitnami /opt/bitnami
