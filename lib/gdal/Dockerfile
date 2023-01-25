# syntax=docker/dockerfile:1.4
ARG RUN_TESTS=0

FROM docker.io/bitnami/minideb:bullseye as builder

ARG RUN_TESTS
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN install_packages ca-certificates curl git build-essential g++ cmake tar gzip bzip2 pkg-config \
    libsqlite3-dev libtiff-dev libcurl4-gnutls-dev python3 sqlite3 python3-lib2to3

ARG GEOS_VERSION=3.11.1
ARG GDAL_VERSION=3.6.2

COPY --link lib/build /opt/bitnami
COPY --from=ghcr.io/bitcompat/json-c:0.16-20220414-bullseye-r1 /opt/bitnami/common/ /opt/bitnami/postgresql/
RUN sed -i 's/\/common/\/postgresql/' /opt/bitnami/postgresql/lib/pkgconfig/json-c.pc

ADD --link https://download.osgeo.org/geos/geos-${GEOS_VERSION}.tar.bz2 /opt/src/geos-${GEOS_VERSION}.tar.bz2
ADD --link https://github.com/OSGeo/gdal/releases/download/v${GDAL_VERSION}/gdal-${GDAL_VERSION}.tar.gz /opt/src/gdal-${GDAL_VERSION}.tar.gz

RUN mkdir -p /opt/src
RUN echo "/opt/bitnami/common/lib" >> /etc/ld.so.conf

RUN <<EOT bash
    cd /opt/src
    tar xf geos-${GEOS_VERSION}.tar.bz2
    cd geos-${GEOS_VERSION}

    mkdir build
    cd build

    BUILD_TESTING=OFF
    if [[ "${RUN_TESTS}" != "0" ]]; then
      BUILD_TESTING=ON
    fi

    cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/opt/bitnami/postgresql -DBUILD_TESTING=\$BUILD_TESTING
    make -j\$(nproc)

    if [[ "${RUN_TESTS}" != "0" ]]; then
      ctest
    fi
    make install
EOT

RUN <<EOT bash
    set -eu

    cd /opt/src
    tar xf gdal-${GDAL_VERSION}.tar.gz
    cd gdal-${GDAL_VERSION}

    mkdir build
    cd build
    cmake .. -DBUILD_APPS=ON -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=/opt/bitnami/postgresql \
      -DPROJ_INCLUDE_DIR=/opt/bitnami/postgresql/include \
      -DODBC_INCLUDE_DIR=/opt/bitnami/common/include \
      -DJSONC_INCLUDE_DIR=/opt/bitnami/postgresql/include/json-c \
      -DGEOS_INCLUDE_DIR=/opt/bitnami/postgresql/include \
      -DODBC_LIBRARY=/opt/bitnami/common/lib/libodbc.so \
      -DODBC_ODBCINST_LIBRARY=/opt/bitnami/common/lib/libodbcinst.so \
      -DJSONC_LIBRARY=/opt/bitnami/common/lib/libjson-c.a \
      -DGEOS_LIBRARY=/opt/bitnami/postgresql/lib/libgeos.a \
      -DGDAL_USE_JSONC=ON \
      -DGDAL_USE_GEOS=ON \
      -DGDAL_USE_ODBC=ON
    cmake --build . -j\$(nproc)
    cmake --build . --target install
EOT

FROM docker.io/bitnami/minideb:bullseye as stage-0

COPY --link --from=builder /opt/bitnami /opt/bitnami
