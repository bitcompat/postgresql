# syntax=docker/dockerfile:1.17
ARG SERVER_VERSION
ARG RUN_TESTS=0
ARG EXTRA_LOCALES=""
ARG WITH_ALL_LOCALES="no"

FROM docker.io/bitnami/minideb:bookworm AS stage-0

ARG TARGETPLATFORM
ARG RUN_TESTS

ARG EXTRA_LOCALES
ARG WITH_ALL_LOCALES

COPY prebuildfs /
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Install required system packages and dependencies
COPY build/$TARGETPLATFORM/* /opt/bitnami/

RUN install_packages ca-certificates curl gzip libbz2-1.0 tar procps zlib1g locales bzip2 tzdata build-essential g++ \
    systemtap-sdt-dev pkg-config libicu-dev flex bison libreadline-dev zlib1g-dev libldap2-dev libpam-dev libssl-dev \
    libxml2-dev libxml2-utils libxslt1-dev libzstd-dev uuid-dev gettext libperl-dev libipc-run-perl liblz4-dev xsltproc \
    zstd git maven openjdk-17-jdk-headless libpcre3-dev libtiff6 file libyaml-dev libbz2-dev meson ninja-build cmake \
    autoconf automake m4 libtool

ARG SERVER_VERSION
ARG PGAUDIT_17_VERSION=17.1
ARG PGAUDIT_16_VERSION=16.1
ARG PGAUDIT_15_VERSION=1.7.1
ARG PGAUDIT_14_VERSION=1.6.3
ARG PGAUDIT_13_VERSION=1.5.3

ARG ORAFCE_VERSION=4.14.4
ARG FAILOVER_SLOTS_VERSION=1.1.0
ARG PLJAVA_VERSION=1.6.9
ARG POSTGIS_VERSION=3.5.3
ARG PGVECTOR_VERSION=0.8.0
ARG PGBACKREST_VERSION=2.56.0
ARG WAL2JSON_VERSION=2.6
ARG PSQL_ODBC_VERSION=17.0.6

ADD --link https://download.osgeo.org/postgis/source/postgis-${POSTGIS_VERSION}.tar.gz /opt/src/postgis.tar.gz

RUN groupadd -g1000 postgres
RUN adduser --no-create-home --home / --uid 1000 --gid 1000 --disabled-password --disabled-login postgres

ARG PG_BASEDIR=/opt/bitnami/postgresql
ENV PATH="/opt/bitnami/common/bin:/opt/bitnami/postgresql/bin:$PATH"

RUN <<EOT bash
    set -ex
    export PG_MAJOR=\$(echo "${SERVER_VERSION}" | cut -d'.' -f1)
    export PG_MINOR=\$(echo "${SERVER_VERSION}" | cut -d'.' -f2)
    mkdir -p /opt/bitnami/postgresql/licenses
    echo "postgis-${POSTGIS_VERSION},GPL-2.0-or-later,http://download.osgeo.org/postgis/source/postgis-${POSTGIS_VERSION}.tar.gz" > /opt/bitnami/postgresql/licenses/gpl-source-links.txt

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
      su -c "/bin/bash -c 'make check-world || (cat /opt/src/postgresql-\$PG_MAJOR.\$PG_MINOR/src/test/regress/log/*.log && false)'" postgres
    fi
    make install-world-bin
    cp COPYRIGHT /opt/bitnami/postgresql/licenses/postgresql-${SERVER_VERSION}.txt
EOT

RUN echo "/opt/bitnami/common/lib" >> /etc/ld.so.conf
RUN echo "/opt/bitnami/postgresql/lib" >> /etc/ld.so.conf
RUN ldconfig /opt/bitnami/postgresql/lib

RUN --mount=type=cache,target=/root/.m2 <<EOT bash
    set -ex
    export PG_MAJOR=\$(echo "${SERVER_VERSION}" | cut -d'.' -f1)
    export PG_MINOR=\$(echo "${SERVER_VERSION}" | cut -d'.' -f2)

    tagname=PGAUDIT_\${PG_MAJOR}_VERSION
    cd /opt/src
    git clone -b \${!tagname} https://github.com/pgaudit/pgaudit.git pgaudit
    cd pgaudit
    make install -j\$(nproc) USE_PGXS=1 PG_CONFIG=$PG_BASEDIR/bin/pg_config
    cp LICENSE /opt/bitnami/postgresql/licenses/pgaudit-\${!tagname}.txt

    cd /opt/src
    git clone -b "VERSION_\${ORAFCE_VERSION//./_}" https://github.com/orafce/orafce.git orafce
    cd orafce
    make install -j\$(nproc) USE_PGXS=1 PG_CONFIG=$PG_BASEDIR/bin/pg_config
    cp COPYRIGHT.orafce /opt/bitnami/postgresql/licenses/orafce-${ORAFCE_VERSION}.txt

    cd /opt/src
    git clone -b "v${FAILOVER_SLOTS_VERSION}" https://github.com/EnterpriseDB/pg_failover_slots.git pg_failover_slots
    cd pg_failover_slots
    make install -j\$(nproc) USE_PGXS=1 PG_CONFIG=$PG_BASEDIR/bin/pg_config
    cp LICENSE /opt/bitnami/postgresql/licenses/pg-failover-slots-${FAILOVER_SLOTS_VERSION}.txt

    cd /opt/src
    git clone -b "V\${PLJAVA_VERSION//./_}" https://github.com/tada/pljava.git pljava
    cd pljava
    mvn clean install -Dpgsql.pgconfig=$PG_BASEDIR/bin/pg_config
    java -jar pljava-packaging/target/pljava-pg\$PG_MAJOR.jar
    cp COPYRIGHT /opt/bitnami/postgresql/licenses/pljava-${PLJAVA_VERSION}.txt

    set -ex
    cd /opt/src
    tar xvf postgis.tar.gz
    cd postgis-${POSTGIS_VERSION}
    PKG_CONFIG_PATH=/opt/bitnami/postgresql/lib/pkgconfig:/opt/bitnami/common/lib/pkgconfig:\$PKG_CONFIG_PATH ./configure \
        --with-pgconfig=$PG_BASEDIR/bin/pg_config --with-projdir=/opt/bitnami/postgresql \
        --with-geosconfig=/opt/bitnami/postgresql/bin/geos-config --prefix=$PG_BASEDIR
    make -j\$(nproc) USE_PGXS=1
    make install
    cp LICENSE.TXT /opt/bitnami/postgresql/licenses/postgis-${POSTGIS_VERSION}.txt

    cd /opt/src
    git clone -b release/${PGBACKREST_VERSION} https://github.com/pgbackrest/pgbackrest.git pgbackrest
    cd pgbackrest
    PKG_CONFIG_PATH=/opt/bitnami/postgresql/lib/pkgconfig:\$PKG_CONFIG_PATH meson setup build --prefix=$PG_BASEDIR
    cd build
    ninja
    ninja install
    cp ../LICENSE /opt/bitnami/postgresql/licenses/pgbackrest-${PGBACKREST_VERSION}.txt

    cd /opt/src
    git clone --branch v${PGVECTOR_VERSION} https://github.com/pgvector/pgvector.git
    cd pgvector
    make
    make install
    cp LICENSE /opt/bitnami/postgresql/licenses/pgvector-${PGVECTOR_VERSION}.txt

    cd /opt/src
    export PSQL_ODBC_MAJOR=\$(echo "${PSQL_ODBC_VERSION}" | cut -d'.' -f1)
    export PSQL_ODBC_MINOR=\$(echo "${PSQL_ODBC_VERSION}" | cut -d'.' -f2)
    export PSQL_ODBC_REV=\$(echo "${PSQL_ODBC_VERSION}" | cut -d'.' -f3)

    git clone --branch "REL-\$(printf %u_%02u_%04u \$PSQL_ODBC_MAJOR \$PSQL_ODBC_MINOR \$PSQL_ODBC_REV)" https://github.com/postgresql-interfaces/psqlodbc.git
    cd psqlodbc
    autoreconf -i
    PKG_CONFIG_PATH=/opt/bitnami/postgresql/lib/pkgconfig:/opt/bitnami/common/lib/pkgconfig:\$PKG_CONFIG_PATH ./configure \
        --with-pgconfig=$PG_BASEDIR/bin/pg_config --prefix=$PG_BASEDIR
    make
    make install
    cp license.txt /opt/bitnami/postgresql/licenses/psqlodbc-${PSQL_ODBC_VERSION}.txt

    cd /opt/src
    git clone --branch "wal2json_\${WAL2JSON_VERSION//./_}" https://github.com/eulerto/wal2json.git
    cd wal2json
    make
    make install
    cp LICENSE /opt/bitnami/postgresql/licenses/wal2json-${WAL2JSON_VERSION}.0.txt
EOT

COPY --link rootfs /
COPY --from=ghcr.io/bitcompat/nss-wrapper:1.1.16-bookworm-r1 /opt/bitnami/common/* /opt/bitnami/common/lib/

RUN <<EOT bash
    set -ex

    mkdir -p /opt/bitnami/common/licenses
    mv /opt/bitnami/common/lib/nss_wrapper-*.txt /opt/bitnami/common/licenses/
    mv /opt/bitnami/common/lib/nss_wrapper.pl /opt/bitnami/common/bin/
EOT

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
      /opt/bitnami/postgresql/lib/libecpg*.a \
      /opt/bitnami/postgresql/lib/psqlodbc*.{a,la}

    strip --strip-all /opt/bitnami/postgresql/lib/*.so
    strip --strip-all /opt/bitnami/postgresql/bin/* || true

    strip --strip-all /opt/bitnami/common/lib/*.so
    strip --strip-all /opt/bitnami/common/bin/* || true
EOT

FROM docker.io/bitnami/minideb:bookworm AS stage-1

ARG SERVER_VERSION
ARG TARGETPLATFORM

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
LABEL org.opencontainers.image.ref.name="${SERVER_VERSION}.0-debian-12-r0" \
      org.opencontainers.image.version="${SERVER_VERSION}.0"

COPY --from=stage-0 /opt/bitnami /opt/bitnami
RUN <<EOT bash
    install_packages ca-certificates libbsd0 locales libicu72 libreadline8 zlib1g \
    libldap-2.5-0 libpam0g libssl3 libxml2 libpcre3 libsasl2-2 \
    libxslt1.1 libzstd1 libuuid1 liblz4-1 procps libedit2 libsqlite3-0

    localedef -c -f UTF-8 -i en_US en_US.UTF-8
    update-locale LANG=C.UTF-8 LC_MESSAGES=POSIX && DEBIAN_FRONTEND=noninteractive dpkg-reconfigure locales
    echo 'en_GB.UTF-8 UTF-8' >> /etc/locale.gen
    echo 'en_US.UTF-8 UTF-8' >> /etc/locale.gen
    locale-gen

    /opt/bitnami/scripts/postgresql/postunpack.sh
    /opt/bitnami/scripts/locales/generate-locales.sh
EOT

ENV HOME="/" \
    OS_ARCH="$TARGETPLATFORM" \
    OS_FLAVOUR="debian-12" \
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
