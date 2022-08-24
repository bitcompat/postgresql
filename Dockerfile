# syntax=docker/dockerfile:1.4
ARG TARGETPLATFORM
ARG SERVER_VERSION
ARG RUN_TESTS=0
ARG EXTRA_LOCALES=""
ARG WITH_ALL_LOCALES="no"

FROM docker.io/bitnami/minideb:bullseye as prebuild-base

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN install_packages ca-certificates curl git build-essential g++ cmake tar gzip bzip2 pkg-config

FROM prebuild-base as protobuf-build

ARG RUN_TESTS
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

FROM prebuild-base as proj-build

ARG RUN_TESTS

RUN install_packages libsqlite3-dev libtiff-dev libcurl4-gnutls-dev python3 sqlite3 python3-lib2to3

ARG UNIX_ODBC_VERSION=2.3.11
ARG PROJ_VERSION=8.2.1
ARG GEOS_VERSION=3.11.0
ARG GDAL_VERSION=3.5.1

COPY --from=ghcr.io/bitcompat/json-c:0.16-20220414-bullseye-r1 /opt/bitnami/common/ /opt/bitnami/postgresql/
RUN sed -i 's/\/common/\/postgresql/' /opt/bitnami/postgresql/lib/pkgconfig/json-c.pc

ADD --link https://github.com/lurcher/unixODBC/releases/download/2.3.11/unixODBC-2.3.11.tar.gz /opt/src/unixODBC-2.3.11.tar.gz
ADD --link https://download.osgeo.org/proj/proj-${PROJ_VERSION}.tar.gz /opt/src/proj-${PROJ_VERSION}.tar.gz
ADD --link https://download.osgeo.org/geos/geos-${GEOS_VERSION}.tar.bz2 /opt/src/geos-${GEOS_VERSION}.tar.bz2
ADD --link https://github.com/OSGeo/gdal/releases/download/v${GDAL_VERSION}/gdal-${GDAL_VERSION}.tar.gz /opt/src/gdal-${GDAL_VERSION}.tar.gz

RUN mkdir -p /opt/src
RUN echo "/opt/bitnami/common/lib" >> /etc/ld.so.conf
RUN <<EOT bash
    set -eu

    cd /opt/src
    tar xf unixODBC-${UNIX_ODBC_VERSION}.tar.gz
    cd unixODBC-${UNIX_ODBC_VERSION}
    ./configure --prefix=/opt/bitnami/common --with-pic
    make -j\$(nproc)
    make install
EOT

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
EOT

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

ARG TARGETPLATFORM
ARG RUN_TESTS

ARG EXTRA_LOCALES
ARG WITH_ALL_LOCALES

COPY --link prebuildfs /
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Install required system packages and dependencies
COPY --link --from=ghcr.io/bitcompat/gosu:1.14.0-bullseye-r1 /opt/bitnami/* /opt/bitnami/
COPY --link --from=protobuf-build /opt/bitnami/ /opt/bitnami/
COPY --link --from=proj-build /opt/bitnami/ /opt/bitnami/

RUN install_packages ca-certificates curl gzip libbz2-1.0 tar procps zlib1g locales bzip2 tzdata build-essential g++
RUN install_packages systemtap-sdt-dev pkg-config libicu-dev flex bison \
    libreadline-dev zlib1g-dev libldap2-dev libpam-dev libssl-dev libxml2-dev libxml2-utils libxslt1-dev libzstd-dev \
    uuid-dev gettext libperl-dev libipc-run-perl liblz4-dev xsltproc zstd git \
    maven openjdk-17-jdk-headless libpcre3-dev

ARG SERVER_VERSION
ARG PGAUDIT_15_VERSION=1.7beta1
ARG PGAUDIT_14_VERSION=1.6.2
ARG PGAUDIT_13_VERSION=1.5.2
ARG PGAUDIT_12_VERSION=1.4.3
ARG PGAUDIT_11_VERSION=1.3.4
ARG PGAUDIT_11_VERSION=1.2.4

ARG ORAFCE_VERSION=VERSION_3_24_2
ARG AUTOFAILOVER_VERSION=v1.6.4
ARG PLJAVA_VERSION=V1_6_4
ARG POSTGIS_VERSION=3.2.2

ADD --link https://download.osgeo.org/postgis/source/postgis-${POSTGIS_VERSION}.tar.gz /opt/src/postgis.tar.gz

RUN groupadd -g1000 postgres
RUN adduser --no-create-home --home / --uid 1000 --gid 1000 --disabled-password --disabled-login postgres

ARG PG_BASEDIR=/opt/bitnami/postgresql
ENV PATH="/opt/bitnami/common/bin:/opt/bitnami/postgresql/bin:$PATH"

RUN <<EOT bash
    set -ex
    export PG_MAJOR=\$(echo "${SERVER_VERSION}" | cut -d'.' -f1)
    export PG_MINOR=\$(echo "${SERVER_VERSION}" | cut -d'.' -f2)

    mkdir -p /opt/src
    cd /opt/src
    curl -sSL -opostgresql.tar.bz2 https://ftp.postgresql.org/pub/source/v\$PG_MAJOR.\$PG_MINOR/postgresql-\$PG_MAJOR.\$PG_MINOR.tar.bz2
    tar xf postgresql.tar.bz2

    export CONFIGURE_FLAGS="--with-libedit-preferred \
      --with-openssl \
      --with-libxml \
      --with-libxslt \
      --with-readline \
      --prefix=$PG_BASEDIR \
      --sysconfdir=$PG_BASEDIR/etc \
      --datarootdir=$PG_BASEDIR/share \
      --datadir=$PG_BASEDIR/share \
      --bindir=$PG_BASEDIR/bin \
      --libdir=$PG_BASEDIR/lib/ \
      --libexecdir=$PG_BASEDIR/lib/postgresql/ \
      --includedir=$PG_BASEDIR/include/ \
      --with-uuid=e2fs \
      --with-ldap \
      --with-system-tzdata=/usr/share/zoneinfo \
      --enable-tap-tests \
      --with-icu"

    cd postgresql-\$PG_MAJOR.\$PG_MINOR
    ./configure \$CONFIGURE_FLAGS
    make -j\$(nproc) world-bin
    if [[ "${RUN_TESTS}" != "0" ]]; then
      su -c "/bin/bash -c 'make check-world || (cat /opt/src/postgresql-14.5/src/test/regress/log/*.log && false)'" postgres
    fi
    make install-world-bin
EOT

RUN echo "/opt/bitnami/common/lib" >> /etc/ld.so.conf
RUN echo "/opt/bitnami/postgresql/lib" >> /etc/ld.so.conf
RUN ldconfig /opt/bitnami/postgresql/lib
RUN install_packages libtiff5

RUN --mount=type=cache,target=/root/.m2 <<EOT bash
    set -ex
    export PG_MAJOR=\$(echo "${SERVER_VERSION}" | cut -d'.' -f1)
    export PG_MINOR=\$(echo "${SERVER_VERSION}" | cut -d'.' -f2)

    cd /opt/src
    git clone -b REL_\${PG_MAJOR}_STABLE https://github.com/pgaudit/pgaudit.git pgaudit
    cd pgaudit
    make install -j\$(nproc) USE_PGXS=1 PG_CONFIG=$PG_BASEDIR/bin/pg_config

    cd /opt/src
    git clone -b ${ORAFCE_VERSION} https://github.com/orafce/orafce.git orafce
    cd orafce
    make install -j\$(nproc) USE_PGXS=1 PG_CONFIG=$PG_BASEDIR/bin/pg_config

    cd /opt/src
    git clone -b ${AUTOFAILOVER_VERSION} https://github.com/citusdata/pg_auto_failover.git pg_auto_failover
    cd pg_auto_failover
    make install -j\$(nproc) USE_PGXS=1 PG_CONFIG=$PG_BASEDIR/bin/pg_config

    cd /opt/src
    git clone -b ${PLJAVA_VERSION} https://github.com/tada/pljava.git pljava
    cd pljava
    mvn clean install -Dpgsql.pgconfig=$PG_BASEDIR/bin/pg_config
    java -jar pljava-packaging/target/pljava-pg\$PG_MAJOR.jar

    cd /opt/src
    tar xvf postgis.tar.gz
    cd postgis-${POSTGIS_VERSION}
    PKG_CONFIG_PATH=/opt/bitnami/postgresql/lib/pkgconfig:\$PKG_CONFIG_PATH ./configure --with-pgconfig=$PG_BASEDIR/bin/pg_config --with-projdir=/opt/bitnami/postgresql
    make install -j\$(nproc) USE_PGXS=1
EOT

RUN install_packages libyaml-dev libbz2-dev
RUN  <<EOT bash
    set -ex
    cd /opt/src
    git clone -b release/2.40 https://github.com/pgbackrest/pgbackrest.git pgbackrest
    cd pgbackrest/src
    ./configure --prefix=$PG_BASEDIR
    make -j\$(nproc)
    make install
EOT

COPY --link rootfs /
COPY --from=ghcr.io/bitcompat/nss-wrapper:1.1.12-bullseye-r1 /opt/bitnami/common/lib/libnss_wrapper.so /opt/bitnami/common/lib/libnss_wrapper.so

RUN <<EOT bash
    set -ex
    chmod g+rwX /opt/bitnami

    rm -rf /opt/bitnami/postgresql/lib/cmake \
      /opt/bitnami/postgresql/share/bash-completion \
      /opt/bitnami/postgresql/share/doc \
      /opt/bitnami/postgresql/share/man \
      /opt/bitnami/common/share \
      /opt/bitnami/common/lib/*.{a,la} \
      /opt/bitnami/postgresql/lib/libjson-c.a \
      /opt/bitnami/postgresql/lib/libpq.a \
      /opt/bitnami/postgresql/lib/libprotobuf*.{a,la} \
      /opt/bitnami/postgresql/lib/libprotoc.{a,la} \
      /opt/bitnami/postgresql/lib/libecpg*.a

    strip --strip-all /opt/bitnami/postgresql/lib/*.so
    strip --strip-all /opt/bitnami/postgresql/bin/* || true

    strip --strip-all /opt/bitnami/common/lib/*.so
    strip --strip-all /opt/bitnami/common/bin/* || true
EOT

FROM docker.io/bitnami/minideb:bullseye AS stage-1

ARG TARGETPLATFORM
ARG SERVER_VERSION

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
LABEL org.opencontainers.image.ref.name="${SERVER_VERSION}.0-debian-11-r0" \
      org.opencontainers.image.version="${SERVER_VERSION}.0"

COPY --from=stage-0 /opt/bitnami /opt/bitnami
RUN <<EOT bash
    install_packages acl curl ca-certificates locales libicu67 libreadline8 zlib1g \
    libldap-2.4-2 libpam0g libssl1.1 libxml2 openssl \
    libxslt1.1 libzstd1 libuuid1 liblz4-1 procps libedit2 libsqlite3-0

    localedef -c -f UTF-8 -i en_US en_US.UTF-8
    update-locale LANG=C.UTF-8 LC_MESSAGES=POSIX && DEBIAN_FRONTEND=noninteractive dpkg-reconfigure locales
    echo 'en_GB.UTF-8 UTF-8' >> /etc/locale.gen && locale-gen
    echo 'en_US.UTF-8 UTF-8' >> /etc/locale.gen && locale-gen

    /opt/bitnami/scripts/postgresql/postunpack.sh
    /opt/bitnami/scripts/locales/add-extra-locales.sh
EOT

LABEL org.opencontainers.image.ref.name="${SERVER_VERSION}.0-debian-11-r0" \
      org.opencontainers.image.version="${SERVER_VERSION}.0"

ENV HOME="/" \
    OS_ARCH="$TARGETPLATFORM" \
    OS_FLAVOUR="debian-11" \
    OS_NAME="linux" \
    APP_VERSION="${SERVER_VERSION}.0" \
    BITNAMI_APP_NAME="postgresql" \
    LANG="en_US.UTF-8" \
    LANGUAGE="en_US:en" \
    NSS_WRAPPER_LIB="/opt/bitnami/common/lib/libnss_wrapper.so" \
    PATH="/opt/bitnami/common/bin:/opt/bitnami/postgresql/bin:$PATH"

VOLUME [ "/bitnami/postgresql", "/docker-entrypoint-initdb.d", "/docker-entrypoint-preinitdb.d" ]

EXPOSE 5432

USER 1001
ENTRYPOINT [ "/opt/bitnami/scripts/postgresql/entrypoint.sh" ]
CMD [ "/opt/bitnami/scripts/postgresql/run.sh" ]
