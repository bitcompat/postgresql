# PostgreSQL

## What is PostgreSQL?

> PostgreSQL (Postgres) is an open source object-relational database known for reliability and data integrity. ACID-compliant, it supports foreign keys, joins, views, triggers and stored procedures.

[Overview of PostgreSQL](https://www.postgresql.org)

Trademarks: The respective trademarks mentioned in this document are owned by the respective companies, and use of them does not imply any affiliation or endorsement.

## TL;DR

```console
docker run --name postgresql ghcr.io/bitcompat/postgresql:latest
```

**Warning**: This quick setup is only intended for development environments. You are encouraged to change the insecure default credentials and check out the available configuration options in the [Configuration](#configuration) section for a more secure deployment.

## Why use a non-root container?

Non-root container images add an extra layer of security and are generally recommended for production environments.

## Get this image

The recommended way to get the PostgreSQL Docker Image is to pull the prebuilt image from the [AWS Public ECR Gallery](https://gallery.ecr.aws/bitcompat/postgresql) or from the [GitHub Container Registry](https://github.com/bitcompat/postgresql/pkgs/container/postgresql)

```console
docker pull ghcr.io/bitcompat/postgresql:latest
```

To use a specific version, you can pull a versioned tag. You can view the [list of available versions](https://github.com/bitcompat/postgresql/pkgs/container/postgresql/versions) in the GitHub Registry or the [available tags](https://gallery.ecr.aws/bitcompat/postgresql) in the public ECR gallery.

```console
docker pull ghcr.io/bitcompat/postgresql:[TAG]
```

## Persisting your database

If you remove the container all your data and configurations will be lost, and the next time you run the image the database will be reinitialized. To avoid this loss of data, you should mount a volume that will persist even after the container is removed.

For persistence you should mount a directory at the `/bitnami/postgresql` path. If the mounted directory is empty, it will be initialized on the first run.

```console
docker run \
    -v /path/to/postgresql-persistence:/bitnami/postgresql \
    ghcr.io/bitcompat/postgresql:latest
```

> NOTE: As this is a non-root container, the mounted files and directories must have the proper permissions for the UID `1001`.

## Connecting to other containers

Using [Docker container networking](https://docs.docker.com/engine/userguide/networking/), a PostgreSQL server running inside a container can easily be accessed by your application containers.

Containers attached to the same network can communicate with each other using the container name as the hostname.

### Using the Command Line

In this example, we will create a PostgreSQL client instance that will connect to the server instance that is running on the same docker network as the client.

#### Step 1: Create a network

```console
docker network create app-tier --driver bridge
```

#### Step 2: Launch the PostgreSQL server instance

Use the `--network app-tier` argument to the `docker run` command to attach the PostgreSQL container to the `app-tier` network.

```console
docker run -d --name postgresql-server \
    --network app-tier \
    ghcr.io/bitcompat/postgresql:latest
```

#### Step 3: Launch your PostgreSQL client instance

Finally we create a new container instance to launch the PostgreSQL client and connect to the server created in the previous step:

```console
docker run -it --rm \
    --network app-tier \
    ghcr.io/bitcompat/postgresql:latest psql -h postgresql-server -U postgres
```

### Using a Docker Compose file

When not specified, Docker Compose automatically sets up a new network and attaches all deployed services to that network. However, we will explicitly define a new `bridge` network named `app-tier`. In this example we assume that you want to connect to the PostgreSQL server from your own custom application image which is identified in the following snippet by the service name `myapp`.

```yaml
version: '2'

networks:
  app-tier:
    driver: bridge

services:
  postgresql:
    image: ghcr.io/bitcompat/postgresql:latest
    networks:
      - app-tier
  myapp:
    image: YOUR_APPLICATION_IMAGE
    networks:
      - app-tier
```

> **IMPORTANT**:
>
> 1. Please update the **YOUR_APPLICATION_IMAGE_** placeholder in the above snippet with your application image
> 2. In your application container, use the hostname `postgresql` to connect to the PostgreSQL server

Launch the containers using:

```console
docker-compose up -d
```

## Configuration

### Environment variables

#### Customizable environment variables

| Name                                       | Description                                                                                          | Default Value                              |
|--------------------------------------------|------------------------------------------------------------------------------------------------------|--------------------------------------------|
| `POSTGRESQL_VOLUME_DIR`                    | Persistence base directory                                                                           | `/bitnami/postgresql`                      |
| `POSTGRESQL_DATA_DIR`                      | PostgreSQL data directory                                                                            | `${POSTGRESQL_VOLUME_DIR}/data`            |
| `POSTGRESQL_EXTRA_FLAGS`                   | Extra flags for PostgreSQL initialization                                                            | `nil`                                      |
| `POSTGRESQL_INIT_MAX_TIMEOUT`              | Maximum initialization waiting timeout                                                               | `60`                                       |
| `POSTGRESQL_PGCTLTIMEOUT`                  | Maximum waiting timeout for pg_ctl commands                                                          | `60`                                       |
| `POSTGRESQL_SHUTDOWN_MODE`                 | Default mode for pg_ctl stop command                                                                 | `fast`                                     |
| `POSTGRESQL_CLUSTER_APP_NAME`              | Replication cluster default application name                                                         | `walreceiver`                              |
| `POSTGRESQL_DATABASE`                      | Default PostgreSQL database                                                                          | `postgres`                                 |
| `POSTGRESQL_INITDB_ARGS`                   | Optional args for PostreSQL initdb operation                                                         | `nil`                                      |
| `ALLOW_EMPTY_PASSWORD`                     | Allow password-less access                                                                           | `no`                                       |
| `POSTGRESQL_INITDB_WAL_DIR`                | Optional init db wal directory                                                                       | `nil`                                      |
| `POSTGRESQL_MASTER_HOST`                   | PostgreSQL master host (used by slaves)                                                              | `nil`                                      |
| `POSTGRESQL_MASTER_PORT_NUMBER`            | PostgreSQL master host port (used by slaves)                                                         | `5432`                                     |
| `POSTGRESQL_NUM_SYNCHRONOUS_REPLICAS`      | Number of PostgreSQL replicas that should use synchronous replication                                | `0`                                        |
| `POSTGRESQL_SYNCHRONOUS_REPLICAS_MODE`     | PostgreSQL synchronous replication mode (values: empty, FIRST, ANY)                                  | `nil`                                      |
| `POSTGRESQL_PORT_NUMBER`                   | PostgreSQL port number                                                                               | `5432`                                     |
| `POSTGRESQL_ALLOW_REMOTE_CONNECTIONS`      | Modify pg_hba settings so users can access from the outside                                          | `yes`                                      |
| `POSTGRESQL_REPLICATION_MODE`              | PostgreSQL replication mode (values: master, slave)                                                  | `master`                                   |
| `POSTGRESQL_REPLICATION_USER`              | PostgreSQL replication user                                                                          | `nil`                                      |
| `POSTGRESQL_REPLICATION_USE_PASSFILE`      | Use PGPASSFILE instead of PGPASSWORD                                                                 | `no`                                       |
| `POSTGRESQL_REPLICATION_PASSFILE_PATH`     | Path to store passfile                                                                               | `${POSTGRESQL_CONF_DIR}/.pgpass`           |
| `POSTGRESQL_SR_CHECK`                      | Create user on PostgreSQL for Stream Replication Check                                               | `no`                                       |
| `POSTGRESQL_SR_CHECK_USERNAME`             | Stream Replication Check user                                                                        | `sr_check_user`                            |
| `POSTGRESQL_SR_CHECK_DATABASE`             | Stream Replication Check database                                                                    | `postgres`                                 |
| `POSTGRESQL_SYNCHRONOUS_COMMIT_MODE`       | Enable synchronous replication in slaves (number defined by POSTGRESQL_NUM_SYNCHRONOUS_REPLICAS)     | `on`                                       |
| `POSTGRESQL_FSYNC`                         | Enable fsync in write ahead logs                                                                     | `on`                                       |
| `POSTGRESQL_USERNAME`                      | PostgreSQL default username                                                                          | `postgres`                                 |
| `POSTGRESQL_ENABLE_LDAP`                   | Enable LDAP for PostgreSQL authentication                                                            | `no`                                       |
| `POSTGRESQL_LDAP_URL`                      | PostgreSQL LDAP server url (requires POSTGRESQL_ENABLE_LDAP=yes)                                     | `nil`                                      |
| `POSTGRESQL_LDAP_PREFIX`                   | PostgreSQL LDAP prefix (requires POSTGRESQL_ENABLE_LDAP=yes)                                         | `nil`                                      |
| `POSTGRESQL_LDAP_SUFFIX`                   | PostgreSQL LDAP suffix (requires POSTGRESQL_ENABLE_LDAP=yes)                                         | `nil`                                      |
| `POSTGRESQL_LDAP_SERVER`                   | PostgreSQL LDAP server (requires POSTGRESQL_ENABLE_LDAP=yes)                                         | `nil`                                      |
| `POSTGRESQL_LDAP_PORT`                     | PostgreSQL LDAP port (requires POSTGRESQL_ENABLE_LDAP=yes)                                           | `nil`                                      |
| `POSTGRESQL_LDAP_SCHEME`                   | PostgreSQL LDAP scheme (requires POSTGRESQL_ENABLE_LDAP=yes)                                         | `nil`                                      |
| `POSTGRESQL_LDAP_TLS`                      | PostgreSQL LDAP tls setting (requires POSTGRESQL_ENABLE_LDAP=yes)                                    | `nil`                                      |
| `POSTGRESQL_LDAP_BASE_DN`                  | PostgreSQL LDAP base DN settings (requires POSTGRESQL_ENABLE_LDAP=yes)                               | `nil`                                      |
| `POSTGRESQL_LDAP_BIND_DN`                  | PostgreSQL LDAP bind DN settings (requires POSTGRESQL_ENABLE_LDAP=yes)                               | `nil`                                      |
| `POSTGRESQL_LDAP_BIND_PASSWORD`            | PostgreSQL LDAP bind password (requires POSTGRESQL_ENABLE_LDAP=yes)                                  | `nil`                                      |
| `POSTGRESQL_LDAP_SEARCH_ATTR`              | PostgreSQL LDAP search attribute (requires POSTGRESQL_ENABLE_LDAP=yes)                               | `nil`                                      |
| `POSTGRESQL_LDAP_SEARCH_FILTER`            | PostgreSQL LDAP search filter (requires POSTGRESQL_ENABLE_LDAP=yes)                                  | `nil`                                      |
| `POSTGRESQL_INITSCRIPTS_USERNAME`          | Username for the psql scripts included in /docker-entrypoint.initdb                                  | `$POSTGRESQL_USERNAME`                     |
| `POSTGRESQL_PASSWORD`                      | Password for the PostgreSQL created user                                                             | `nil`                                      |
| `POSTGRESQL_POSTGRES_PASSWORD`             | Password for the PostgreSQL postgres user                                                            | `nil`                                      |
| `POSTGRESQL_REPLICATION_PASSWORD`          | Password for the PostgreSQL replication user                                                         | `nil`                                      |
| `POSTGRESQL_SR_CHECK_PASSWORD`             | Password for the Stream Replication Check user                                                       | `nil`                                      |
| `POSTGRESQL_INITSCRIPTS_PASSWORD`          | Password for the PostgreSQL init scripts user                                                        | `$POSTGRESQL_PASSWORD`                     |
| `POSTGRESQL_ENABLE_TLS`                    | Whether to enable TLS for traffic or not                                                             | `no`                                       |
| `POSTGRESQL_TLS_CERT_FILE`                 | File containing the certificate for the TLS traffic                                                  | `nil`                                      |
| `POSTGRESQL_TLS_KEY_FILE`                  | File containing the key for certificate                                                              | `nil`                                      |
| `POSTGRESQL_TLS_CA_FILE`                   | File containing the CA of the certificate                                                            | `nil`                                      |
| `POSTGRESQL_TLS_CRL_FILE`                  | File containing a Certificate Revocation List                                                        | `nil`                                      |
| `POSTGRESQL_TLS_PREFER_SERVER_CIPHERS`     | Whether to use the server TLS cipher preferences rather than the client                              | `yes`                                      |
| `POSTGRESQL_SHARED_PRELOAD_LIBRARIES`      | List of libraries to preload at PostgreSQL initialization                                            | `pgaudit`                                  |
| `POSTGRESQL_PGAUDIT_LOG`                   | Comma-separated list of actions to log with pgaudit                                                  | `nil`                                      |
| `POSTGRESQL_PGAUDIT_LOG_CATALOG`           | Enable pgaudit log catalog (pgaudit.log_catalog setting)                                             | `nil`                                      |
| `POSTGRESQL_PGAUDIT_LOG_PARAMETER`         | Enable pgaudit log parameter (pgaudit.log_parameter setting)                                         | `nil`                                      |
| `POSTGRESQL_LOG_CONNECTIONS`               | Add a log entry per user connection                                                                  | `nil`                                      |
| `POSTGRESQL_LOG_DISCONNECTIONS`            | Add a log entry per user disconnection                                                               | `nil`                                      |
| `POSTGRESQL_LOG_HOSTNAME`                  | Log the client host name when accessing                                                              | `nil`                                      |
| `POSTGRESQL_CLIENT_MIN_MESSAGES`           | Set log level of errors to send to the client                                                        | `error`                                    |
| `POSTGRESQL_LOG_LINE_PREFIX`               | Set the format of the log lines                                                                      | `nil`                                      |
| `POSTGRESQL_LOG_TIMEZONE`                  | Set the log timezone                                                                                 | `nil`                                      |
| `POSTGRESQL_TIMEZONE`                      | Set the timezone                                                                                     | `nil`                                      |
| `POSTGRESQL_MAX_CONNECTIONS`               | Set the maximum amount of connections                                                                | `nil`                                      |
| `POSTGRESQL_TCP_KEEPALIVES_IDLE`           | Set the TCP keepalive idle time                                                                      | `nil`                                      |
| `POSTGRESQL_TCP_KEEPALIVES_INTERVAL`       | Set the TCP keepalive interval time                                                                  | `nil`                                      |
| `POSTGRESQL_TCP_KEEPALIVES_COUNT`          | Set the TCP keepalive count                                                                          | `nil`                                      |
| `POSTGRESQL_STATEMENT_TIMEOUT`             | Set the SQL statement timeout                                                                        | `nil`                                      |
| `POSTGRESQL_PGHBA_REMOVE_FILTERS`          | Comma-separated list of strings for removing pg_hba.conf lines (example: md5, local)                 | `nil`                                      |
| `POSTGRESQL_USERNAME_CONNECTION_LIMIT`     | Set the user connection limit                                                                        | `nil`                                      |
| `POSTGRESQL_POSTGRES_CONNECTION_LIMIT`     | Set the postgres user connection limit                                                               | `nil`                                      |
| `POSTGRESQL_WAL_LEVEL`                     | Set the write-ahead log level                                                                        | `replica`                                  |
| `POSTGRESQL_DEFAULT_TOAST_COMPRESSION`     | Set the postgres default compression                                                                 | `nil`                                      |
| `POSTGRESQL_PASSWORD_ENCRYPTION`           | Set the passwords encryption method                                                                  | `nil`                                      |
| `POSTGRESQL_DEFAULT_TRANSACTION_ISOLATION` | Set transaction isolation                                                                            | `nil`                                      |
| `POSTGRESQL_REPLICATION_NODES`             | Override value for synchronous_standby_names in postgresql.conf. Should be set if `REPMGR_NODE_NAME` | `nil`                                      |
| `POSTGRESQL_PERFORM_RESTORE`               | Flag to skip deletion of `recovery.signal` file to enable native recovery. e.g by using `wal-g`      | `no`                                       |
| `POSTGRESQL_AUTOCTL_CONF_DIR`              | Path to the configuration dir for the pg_autoctl command                                             | `${POSTGRESQL_AUTOCTL_VOLUME_DIR}/.config` |
| `POSTGRESQL_AUTOCTL_MODE`                  | pgAutoFailover node type, valid values [monitor, postgres]                                           | `postgres`                                 |
| `POSTGRESQL_AUTOCTL_MONITOR_HOST`          | Hostname for the monitor component                                                                   | `monitor`                                  |
| `POSTGRESQL_AUTOCTL_HOSTNAME`              | Hostname by which postgres is reachable                                                              | `$(hostname --fqdn)`                       |

#### Read-only environment variables

| Name                                         | Description                                                     | Value                                         |
|----------------------------------------------|-----------------------------------------------------------------|-----------------------------------------------|
| `POSTGRESQL_BASE_DIR`                        | PostgreSQL installation directory                               | `/opt/bitnami/postgresql`                     |
| `POSTGRESQL_DEFAULT_CONF_DIR`                | PostgreSQL configuration directory                              | `$POSTGRESQL_BASE_DIR/conf.default`           |
| `POSTGRESQL_CONF_DIR`                        | PostgreSQL configuration directory                              | `$POSTGRESQL_BASE_DIR/conf`                   |
| `POSTGRESQL_MOUNTED_CONF_DIR`                | PostgreSQL mounted configuration directory                      | `$POSTGRESQL_VOLUME_DIR/conf`                 |
| `POSTGRESQL_CONF_FILE`                       | PostgreSQL configuration file                                   | `$POSTGRESQL_CONF_DIR/postgresql.conf`        |
| `POSTGRESQL_PGHBA_FILE`                      | PostgreSQL pg_hba file                                          | `$POSTGRESQL_CONF_DIR/pg_hba.conf`            |
| `POSTGRESQL_RECOVERY_FILE`                   | PostgreSQL recovery file                                        | `$POSTGRESQL_DATA_DIR/recovery.conf`          |
| `POSTGRESQL_LOG_DIR`                         | PostgreSQL logs directory                                       | `$POSTGRESQL_BASE_DIR/logs`                   |
| `POSTGRESQL_LOG_FILE`                        | PostgreSQL log file                                             | `$POSTGRESQL_LOG_DIR/postgresql.log`          |
| `POSTGRESQL_TMP_DIR`                         | PostgreSQL temporary directory                                  | `$POSTGRESQL_BASE_DIR/tmp`                    |
| `POSTGRESQL_PID_FILE`                        | PostgreSQL PID file                                             | `$POSTGRESQL_TMP_DIR/postgresql.pid`          |
| `POSTGRESQL_BIN_DIR`                         | PostgreSQL executables directory                                | `$POSTGRESQL_BASE_DIR/bin`                    |
| `POSTGRESQL_INITSCRIPTS_DIR`                 | Init scripts directory                                          | `/docker-entrypoint-initdb.d`                 |
| `POSTGRESQL_PREINITSCRIPTS_DIR`              | Pre-init scripts directory                                      | `/docker-entrypoint-preinitdb.d`              |
| `POSTGRESQL_DAEMON_USER`                     | PostgreSQL system user                                          | `postgres`                                    |
| `POSTGRESQL_DAEMON_GROUP`                    | PostgreSQL system group                                         | `postgres`                                    |
| `POSTGRESQL_USE_CUSTOM_PGHBA_INITIALIZATION` | Initialize PostgreSQL with the custom, mounted pg_hba.conf file | `no`                                          |
| `POSTGRESQL_AUTOCTL_VOLUME_DIR`              | The pg_autoctl home directory                                   | `${POSTGRESQL_VOLUME_DIR}/pgautoctl`          |
| `POSTGRESQL_PGBACKREST_VOLUME_DIR`           | The pgbackrest home directory                                   | `${POSTGRESQL_VOLUME_DIR}/pgbackrest`         |
| `POSTGRESQL_PGBACKREST_LOGS_DIR`             | The pgbackrest logs directory                                   | `${POSTGRESQL_PGBACKREST_VOLUME_DIR}/logs`    |
| `POSTGRESQL_PGBACKREST_BACKUPS_DIR`          | The pgbackrest backups directory                                | `${POSTGRESQL_PGBACKREST_VOLUME_DIR}/backups` |
| `POSTGRESQL_PGBACKREST_SPOOL_DIR`            | The pgbackrest spool directory                                  | `${POSTGRESQL_PGBACKREST_VOLUME_DIR}/spool`   |
| `POSTGRESQL_PGBACKREST_CONF_FILE`            | The pgbackrest configuration file                               | `${POSTGRESQL_DATA_DIR}/pgbackrest.conf`      |
| `POSTGRESQL_FIRST_BOOT`                      | Flag for startup (necessary for repmgr)                         | `yes`                                         |
| `NSS_WRAPPER_LIB`                            | Flag for startup (necessary for repmgr)                         | `/opt/bitnami/common/lib/libnss_wrapper.so`   |

### On container start

When the container is executed, it will execute the files with extension `.sh` located at `/docker-entrypoint-preinitdb.d` before initializing or starting postgresql.

In order to have your custom files inside the docker image you can mount them as a volume.

### Passing extra command-line flags to PostgreSQL

Passing extra command-line flags to the postgresql service command is possible through the following env var:

- `POSTGRESQL_EXTRA_FLAGS`: Flags to be appended to the `postgres` startup command. No defaults

### Initializing a new instance

When the container is executed for the first time, it will execute the files with extensions `.sh`, `.sql` and `.sql.gz` located at `/docker-entrypoint-initdb.d`.

In order to have your custom files inside the docker image you can mount them as a volume.

### Setting the root password on first run

In the above commands you may have noticed the use of the `POSTGRESQL_PASSWORD` environment variable. Passing the `POSTGRESQL_PASSWORD` environment variable when running the image for the first time will set the password of the `postgres` user to the value of `POSTGRESQL_PASSWORD` (or the content of the file specified in `POSTGRESQL_PASSWORD_FILE`).

```console
docker run --name postgresql -e POSTGRESQL_PASSWORD=password123 ghcr.io/bitcompat/postgresql:latest
```

**Note!**
The `postgres` user is a superuser and has full administrative access to the PostgreSQL database.

Refer to [Creating a database user on first run](#creating-a-database-user-on-first-run) if you want to set an unprivileged user and a password for the `postgres` user.

### Creating a database on first run

By passing the `POSTGRESQL_DATABASE` environment variable when running the image for the first time, a database will be created. This is useful if your application requires that a database already exists, saving you from having to manually create the database using the PostgreSQL client.

```console
docker run --name postgresql -e POSTGRESQL_DATABASE=my_database ghcr.io/bitcompat/postgresql:latest
```

### Creating a database user on first run

You can also create a restricted database user that only has permissions for the database created with the [`POSTGRESQL_DATABASE`](#creating-a-database-on-first-run) environment variable. To do this, provide the `POSTGRESQL_USERNAME` environment variable.

```console
docker run --name postgresql -e POSTGRESQL_USERNAME=my_user -e POSTGRESQL_PASSWORD=password123 -e POSTGRESQL_DATABASE=my_database ghcr.io/bitcompat/postgresql:latest
```

**Note!**
When `POSTGRESQL_USERNAME` is specified, the `postgres` user is not assigned a password and as a result you cannot login remotely to the PostgreSQL server as the `postgres` user. If you still want to have access with the user `postgres`, please set the `POSTGRESQL_POSTGRES_PASSWORD` environment variable (or the content of the file specified in `POSTGRESQL_POSTGRES_PASSWORD_FILE`).

### Auditing

The PostgreSQL Image comes with the pgAudit module enabled by default. Thanks to this, audit information can be enabled in the container with these environment variables:

- `POSTGRESQL_PGAUDIT_LOG`: Comma-separated list with different operations to audit. Find in the [official pgAudit documentation](https://github.com/pgaudit/pgaudit#configuration) the list of possible values. No defaults.
- `POSTGRESQL_PGAUDIT_LOG_CATALOG`: Session logging enabled in the case where all relations in a statement are in pg_catalog. No defaults.
- `POSTGRESQL_LOG_CONNECTIONS`: Add log entry for logins. No defaults.
- `POSTGRESQL_LOG_DISCONNECTIONS`: Add log entry for logouts. No defaults.
- `POSTGRESQL_LOG_HOSTNAME`: Log the client hostname. No defaults.
- `POSTGRESQL_LOG_LINE_PREFIX`: Define the format of the log entry lines. Find in the [official PostgreSQL documentation](https://www.postgresql.org/docs/current/runtime-config-logging.html) the string parameters. No defaults.
- `POSTGRESQL_LOG_TIMEZONE`: Set the timezone for the log entry timestamp. No defaults.

### Session settings

The PostgreSQL Image allows configuring several parameters for the connection and session management:

- `POSTGRESQL_USERNAME_CONNECTION_LIMIT`: If a user different from `postgres` is created, set the connection limit. No defaults.
- `POSTGRESQL_POSTGRES_CONNECTION_LIMIT`: Set the connection limit for the `postgres` user. No defaults.
- `POSTGRESQL_STATEMENT_TIMEOUT`: Set the statement timeout. No defaults.
- `POSTGRESQL_TCP_KEEPALIVES_INTERVAL`: TCP keepalive interval. No defaults.
- `POSTGRESQL_TCP_KEEPALIVES_IDLE`: TCP keepalive idle time. No defaults.
- `POSTGRESQL_TCP_KEEPALIVES_COUNT`: TCP keepalive count. No defaults.

### Configuring time zone

The PostgreSQL Image allows configuring the time zone for PostgreSQL with the following environment variables:

- `POSTGRESQL_TIMEZONE`: Sets the time zone for displaying and interpreting time stamps.
- `POSTGRESQL_LOG_TIMEZONE`: Sets the time zone used for timestamps written in the server log.

### Modify pg_hba.conf

By default, the PostgreSQL Image generates `local` and `md5` entries in the pg_hba.conf file. In order to adapt to any other requirements or standards, it is possible to change the pg_hba.conf file by:

- Mounting your own pg_hba.conf file in `/bitnami/postgresql/conf`
- Using the `POSTGRESQL_PGHBA_REMOVE_FILTERS` with a comma-separated list of patterns. All lines that match any of the patterns will be removed. For example, if we want to remove all `local` and `md5` authentication (in favour of hostssl only connections, for example), set `POSTGRESQL_PGHBA_REMOVE_FILTERS=local, md5`.

### Preloading shared libraries

It is possible to modify the list of libraries that PostgreSQL will preload at boot time by setting the `POSTGRESQL_SHARED_PRELOAD_LIBRARIES`. The default value is `POSTGRESQL_SHARED_PRELOAD_LIBRARIES=pgaudit`. If, for example, you want to add the `pg_stat_statements` library to the preload, set `POSTGRESQL_SHARED_PRELOAD_LIBRARIES=pgaudit, pg_stat_statements`.

### Setting up a streaming replication

A [Streaming replication](https://www.postgresql.org/docs/9.4/static/warm-standby.html#STREAMING-REPLICATION) cluster can easily be setup with the PostgreSQL Docker Image using the following environment variables:

- `POSTGRESQL_REPLICATION_MODE`: Replication mode. Possible values `master`/`slave`. No defaults.
- `POSTGRESQL_REPLICATION_USER`: The replication user created on the master on first run. No defaults.
- `POSTGRESQL_REPLICATION_PASSWORD`: The replication users password. No defaults.
- `POSTGRESQL_REPLICATION_PASSWORD_FILE`: Path to a file that contains the replication users password. This will override the value specified in `POSTGRESQL_REPLICATION_PASSWORD`. No defaults.
- `POSTGRESQL_MASTER_HOST`: Hostname/IP of replication master (slave parameter). No defaults.
- `POSTGRESQL_MASTER_PORT_NUMBER`: Server port of the replication master (slave parameter). Defaults to `5432`.

In a replication cluster you can have one master and zero or more slaves. When replication is enabled the master node is in read-write mode, while the slaves are in read-only mode. For best performance its advisable to limit the reads to the slaves.

#### Step 1: Create the replication master

The first step is to start the master.

```console
docker run --name postgresql-master \
  -e POSTGRESQL_REPLICATION_MODE=master \
  -e POSTGRESQL_USERNAME=my_user \
  -e POSTGRESQL_PASSWORD=password123 \
  -e POSTGRESQL_DATABASE=my_database \
  -e POSTGRESQL_REPLICATION_USER=my_repl_user \
  -e POSTGRESQL_REPLICATION_PASSWORD=my_repl_password \
  ghcr.io/bitcompat/postgresql:latest
```

In this command we are configuring the container as the master using the `POSTGRESQL_REPLICATION_MODE=master` parameter. A replication user is specified using the `POSTGRESQL_REPLICATION_USER` and `POSTGRESQL_REPLICATION_PASSWORD` parameters.

#### Step 2: Create the replication slave

Next we start a replication slave container.

```console
docker run --name postgresql-slave \
  --link postgresql-master:master \
  -e POSTGRESQL_REPLICATION_MODE=slave \
  -e POSTGRESQL_MASTER_HOST=master \
  -e POSTGRESQL_MASTER_PORT_NUMBER=5432 \
  -e POSTGRESQL_REPLICATION_USER=my_repl_user \
  -e POSTGRESQL_REPLICATION_PASSWORD=my_repl_password \
  ghcr.io/bitcompat/postgresql:latest
```

In the above command the container is configured as a `slave` using the `POSTGRESQL_REPLICATION_MODE` parameter. Before the replication slave is started, the `POSTGRESQL_MASTER_HOST` and `POSTGRESQL_MASTER_PORT_NUMBER` parameters are used by the slave container to connect to the master and replicate the initial database from the master. The `POSTGRESQL_REPLICATION_USER` and `POSTGRESQL_REPLICATION_PASSWORD` credentials are used to authenticate with the master. In order to change the `pg_hba.conf` default settings, the slave needs to know if `POSTGRESQL_PASSWORD` is set.

With these two commands you now have a two node PostgreSQL master-slave streaming replication cluster up and running. You can scale the cluster by adding/removing slaves without incurring any downtime.

> **Note**: The cluster replicates the master in its entirety, which includes all users and databases.

If the master goes down you can reconfigure a slave to act as the master and begin accepting writes by creating the trigger file `/tmp/postgresql.trigger.5432`. For example the following command reconfigures `postgresql-slave` to act as the master:

```console
docker exec postgresql-slave touch /tmp/postgresql.trigger.5432
```

> **Note**: The configuration of the other slaves in the cluster needs to be updated so that they are aware of the new master. This would require you to restart the other slaves with `--link postgresql-slave:master` as per our examples.

With Docker Compose the master-slave replication can be setup using:

```yaml
version: '2'

services:
  postgresql-master:
    image: ghcr.io/bitcompat/postgresql:latest
    ports:
      - 5432
    volumes:
      - postgresql_master_data:/bitnami/postgresql
    environment:
      - POSTGRESQL_REPLICATION_MODE=master
      - POSTGRESQL_REPLICATION_USER=repl_user
      - POSTGRESQL_REPLICATION_PASSWORD=repl_password
      - POSTGRESQL_USERNAME=my_user
      - POSTGRESQL_PASSWORD=my_password
      - POSTGRESQL_DATABASE=my_database
  postgresql-slave:
    image: ghcr.io/bitcompat/postgresql:latest
    ports:
      - 5432
    depends_on:
      - postgresql-master
    environment:
      - POSTGRESQL_REPLICATION_MODE=slave
      - POSTGRESQL_REPLICATION_USER=repl_user
      - POSTGRESQL_REPLICATION_PASSWORD=repl_password
      - POSTGRESQL_MASTER_HOST=postgresql-master
      - POSTGRESQL_PASSWORD=my_password
      - POSTGRESQL_MASTER_PORT_NUMBER=5432

volumes:
  postgresql_master_data:
```

Scale the number of slaves using:

```console
docker-compose up --detach --scale postgresql-master=1 --scale postgresql-slave=3
```

The above command scales up the number of slaves to `3`. You can scale down in the same way.

> **Note**: You should not scale up/down the number of master nodes. Always have only one master node running.

#### Synchronous commits

By default, the slave instances are configured with asynchronous replication. In order to guarantee more data stability (at the cost of some performance), it is possible to set synchronous commits (i.e. a transaction commit will not return success to the client until it has been written in a set of replicas) using the following environment variables.

- `POSTGRESQL_SYNCHRONOUS_COMMIT_MODE`: Establishes the type of synchronous commit. The available options are: `on`, `remote_apply`, `remote_write`, `local` and `off`. The default value is `on`. For more information, check the [official PostgreSQL documentation](https://www.postgresql.org/docs/9.6/runtime-config-wal.html#GUC-SYNCHRONOUS-COMMIT).
- `POSTGRESQL_NUM_SYNCHRONOUS_REPLICAS`: Establishes the number of replicas that will enable synchronous replication. This number must not be above the number of slaves that you configure in the cluster.

With Docker Compose the master-slave replication with synchronous commits can be setup as follows:

```yaml
version: '2'

services:
  postgresql-master:
    image: ghcr.io/bitcompat/postgresql:latest
    ports:
      - 5432
    volumes:
      - postgresql_master_data:/bitnami/postgresql
    environment:
      - POSTGRESQL_REPLICATION_MODE=master
      - POSTGRESQL_REPLICATION_USER=repl_user
      - POSTGRESQL_REPLICATION_PASSWORD=repl_password
      - POSTGRESQL_USERNAME=my_user
      - POSTGRESQL_PASSWORD=my_password
      - POSTGRESQL_DATABASE=my_database
      - POSTGRESQL_SYNCHRONOUS_COMMIT_MODE=on
      - POSTGRESQL_NUM_SYNCHRONOUS_REPLICAS=1
    volumes:
      - /path/to/postgresql-persistence:/bitnami/postgresql
  postgresql-slave:
    image: ghcr.io/bitcompat/postgresql:latest
    ports:
      - 5432
    depends_on:
      - postgresql-master
    environment:
      - POSTGRESQL_REPLICATION_MODE=slave
      - POSTGRESQL_REPLICATION_USER=repl_user
      - POSTGRESQL_REPLICATION_PASSWORD=repl_password
      - POSTGRESQL_MASTER_HOST=postgresql-master
      - POSTGRESQL_MASTER_PORT_NUMBER=5432
  postgresql-slave2:
    image: ghcr.io/bitcompat/postgresql:latest
    ports:
      - 5432
    depends_on:
      - postgresql-master
    environment:
      - POSTGRESQL_REPLICATION_MODE=slave
      - POSTGRESQL_REPLICATION_USER=repl_user
      - POSTGRESQL_REPLICATION_PASSWORD=repl_password
      - POSTGRESQL_MASTER_HOST=postgresql-master
      - POSTGRESQL_MASTER_PORT_NUMBER=5432
```

In the example above, commits will need to be written to both the master and one of the slaves in order to be accepted. The other slave will continue using asynchronous replication. Check it with the following SQL query:

```console
postgres=# select application_name as server, state,
postgres-#       sync_priority as priority, sync_state
postgres-#       from pg_stat_replication;
| server      | state     | priority | sync_state |
|-------------|-----------|----------|------------|
| walreceiver | streaming | 0        | sync       |
| walreceiver | streaming | 0        | async      |
```

> **Note:** For more advanced setups, you can define different replication groups with the `application_name` parameter, by setting the `POSTGRESQL_CLUSTER_APP_NAME` environment variable.

### LDAP authentication

In order to use LDAP authentication you need to enable it setting the environment variable `POSTGRESQL_ENABLE_LDAP` to  `yes`.

There are two ways of setting up the LDAP configuration:

- By configuring `POSTGRESQL_LDAP_URL`, where you can configure all the associated parameters in the URL.
- Setting up the parameters `POSTGRESQL_LDAP_xxxx` independently.

The LDAP related parameters are:

- `POSTGRESQL_LDAP_SERVER`: IP addresses or names of the LDAP servers to connect to. Separated by spaces.
- `POSTGRESQL_LDAP_PORT`: Port number on the LDAP server to connect to
- `POSTGRESQL_LDAP_SCHEME`: Set to `ldaps` to use LDAPS. Default to none.
- `POSTGRESQL_LDAP_TLS`: Set to `1` to use TLS encryption. Default to none.
- `POSTGRESQL_LDAP_PREFIX`: String to prepend to the user name when forming the DN to bind. Default to none.
- `POSTGRESQL_LDAP_SUFFIX`:  String to append to the user name when forming the DN to bind. Default to none.
- `POSTGRESQL_LDAP_BASE_DN`: Root DN to begin the search for the user in. Default to none.
- `POSTGRESQL_LDAP_BIND_DN`: DN of user to bind to LDAP. Default to none.
- `POSTGRESQL_LDAP_BIND_PASSWORD`: Password for the user to bind to LDAP. Default to none.
- `POSTGRESQL_LDAP_SEARCH_ATTR`: Attribute to match against the user name in the search. Default to none.
- `POSTGRESQL_LDAP_SEARCH_FILTER`: The search filter to use when doing search+bind authentication. Default to none.
- `POSTGRESQL_LDAP_URL`: URL to connect to, in the format: `ldap[s]://host[:port]/basedn[?[attribute][?[scope][?[filter]]]]` .

For more information refer to [Postgresql LDAP auth configuration documentation](https://www.postgresql.org/docs/12/auth-ldap.html).

### Securing PostgreSQL traffic

PostgreSQL supports the encryption of connections using the SSL/TLS protocol. Should you desire to enable this optional feature, you may use the following environment variables to configure the application:

- `POSTGRESQL_ENABLE_TLS`: Whether to enable TLS for traffic or not. Defaults to `no`.
- `POSTGRESQL_TLS_CERT_FILE`: File containing the certificate file for the TLS traffic. No defaults.
- `POSTGRESQL_TLS_KEY_FILE`: File containing the key for certificate. No defaults.
- `POSTGRESQL_TLS_CA_FILE`: File containing the CA of the certificate. If provided, PostgreSQL will authenticate TLS/SSL clients by requesting them a certificate (see [ref](https://www.postgresql.org/docs/9.6/auth-methods.html)). No defaults.
- `POSTGRESQL_TLS_CRL_FILE`: File containing a Certificate Revocation List. No defaults.
- `POSTGRESQL_TLS_PREFER_SERVER_CIPHERS`: Whether to use the server's TLS cipher preferences rather than the client's. Defaults to `yes`.

When enabling TLS, PostgreSQL will support both standard and encrypted traffic by default, but prefer the latter. Below there are some examples on how to quickly set up TLS traffic:

```console
$ docker run \
    -v /path/to/certs:/opt/bitnami/postgresql/certs \
    -e ALLOW_EMPTY_PASSWORD=yes \
    -e POSTGRESQL_ENABLE_TLS=yes \
    -e POSTGRESQL_TLS_CERT_FILE=/opt/bitnami/postgresql/certs/postgres.crt \
    -e POSTGRESQL_TLS_KEY_FILE=/opt/bitnami/postgresql/certs/postgres.key \
    ghcr.io/bitcompat/postgresql:latest
```

Alternatively, you may also provide this configuration in your [custom](https://github.com/bitcompat/postgresql#configuration-file) configuration file.

### Configuration file

The image looks for `postgresql.conf` file in `/opt/bitnami/postgresql/conf/`. You can mount a volume at `/bitnami/postgresql/conf/` and copy/edit the `postgresql.conf` file in the `/path/to/postgresql-persistence/conf/`. The default configurations will be populated to the `conf/` directory if it's empty.

```console
/path/to/postgresql-persistence/conf/
└── postgresql.conf

0 directories, 1 file
```

As PostgreSQL image is non-root, you need to set the proper permissions to the mounted directory in your host:

```console
sudo chown 1001:1001 /path/to/postgresql-persistence/conf/
```

#### Step 1: Run the PostgreSQL image

Run the PostgreSQL image, mounting a directory from your host.

```console
docker run --name postgresql \
    -v /path/to/postgresql-persistence/conf/:/bitnami/postgresql/conf/ \
    ghcr.io/bitcompat/postgresql:latest
```

or using Docker Compose:

```yaml
version: '2'

services:
  postgresql:
    image: ghcr.io/bitcompat/postgresql:latest
    ports:
      - 5432:5432
    volumes:
      - /path/to/postgresql-persistence/conf/:/bitnami/postgresql/conf/
```

#### Step 2: Edit the configuration

Edit the configuration on your host using your favorite editor.

```console
vi /path/to/postgresql-persistence/conf/postgresql.conf
```

#### Step 3: Restart PostgreSQL

After changing the configuration, restart your PostgreSQL container for changes to take effect.

```console
docker restart postgresql
```

or using Docker Compose:

```console
docker-compose restart postgresql
```

Refer to the [server configuration](https://www.postgresql.org/docs/9.4/static/runtime-config.html) manual for the complete list of configuration options.

#### Allow settings to be loaded from files other than the default `postgresql.conf`

Apart of using a custom `postgresql.conf`, you can include files ending in `.conf` from the `conf.d` directory in the volume at `/bitnami/postgresql/conf/`.
For this purpose, the default `postgresql.conf` contains the following section:

```config
##------------------------------------------------------------------------------
## CONFIG FILE INCLUDES
##------------------------------------------------------------------------------

## These options allow settings to be loaded from files other than the
## default postgresql.conf.

include_dir = 'conf.d'  # Include files ending in '.conf' from directory 'conf.d'
```

In your host, you should create the extended configuration file under the `conf.d` directory:

```console
mkdir -p /path/to/postgresql-persistence/conf/conf.d/
vi /path/to/postgresql-persistence/conf/conf.d/extended.conf
```

If you are using your custom `postgresql.conf`, you should create (or uncomment) the above section in your config file, in this case the `/path/to/postgresql-persistence/conf/` structure should be something like

```console
/path/to/postgresql-persistence/conf/
├── conf.d
│   └── extended.conf
└── postgresql.conf

1 directory, 2 files
```

### Specifying initdb arguments

Specifying extra initdb arguments can easily be done using the following environment variables:

- `POSTGRESQL_INITDB_ARGS`: Specifies extra arguments for the initdb command. No defaults.
- `POSTGRESQL_INITDB_WAL_DIR`: Defines a custom location for the transaction log. No defaults.

```console
docker run --name postgresql \
  -e POSTGRESQL_INITDB_ARGS="--data-checksums" \
  -e POSTGRESQL_INITDB_WAL_DIR="/bitnami/waldir" \
  ghcr.io/bitcompat/postgresql:latest
```

### Stopping settings

You can control the parameters used to stop postgresql in the initialization process by using:

- `POSTGRESQL_PGCTLTIMEOUT` that will set the timeout for the `pg_ctl` command.
- `POSTGRESQL_SHUTDOWN_MODE` that will indicate the [shutdown mode](https://www.postgresql.org/docs/11/app-pg-ctl.html) used.

### Installing extra locales

The Dockerfile provides two arguments to configure extra locales at build time:

- `WITH_ALL_LOCALES`: Enable all supported locales. Default: no
- `EXTRA_LOCALES`: Comma separated list of extra locales to enable. No defaults

For example, to build an image with support for the `es_ES.UTF-8 UTF-8` locale, you can add the following argument to your build command:

```console
docker build --build-arg EXTRA_LOCALES="es_ES.UTF-8 UTF-8" ...
```

### Environment variables aliases

The PostgreSQL container allows two different sets of environment variables. Please see the list of environment variable aliases in the next table:

| Environment Variable                 | Alias                              |
|:-------------------------------------|:-----------------------------------|
| POSTGRESQL_USERNAME                  | POSTGRES_USER                      |
| POSTGRESQL_DATABASE                  | POSTGRES_DB                        |
| POSTGRESQL_PASSWORD                  | POSTGRES_PASSWORD                  |
| POSTGRESQL_PASSWORD_FILE             | POSTGRES_PASSWORD_FILE             |
| POSTGRESQL_POSTGRES_PASSWORD         | POSTGRES_POSTGRES_PASSWORD         |
| POSTGRESQL_POSTGRES_PASSWORD_FILE    | POSTGRES_POSTGRES_PASSWORD_FILE    |
| POSTGRESQL_PORT_NUMBER               | POSTGRES_PORT_NUMBER               |
| POSTGRESQL_INITDB_ARGS               | POSTGRES_INITDB_ARGS               |
| POSTGRESQL_INITDB_WAL_DIR            | POSTGRES_INITDB_WAL_DIR            |
| POSTGRESQL_DATA_DIR                  | PGDATA                             |
| POSTGRESQL_REPLICATION_USER          | POSTGRES_REPLICATION_USER          |
| POSTGRESQL_REPLICATION_MODE          | POSTGRES_REPLICATION_MODE          |
| POSTGRESQL_REPLICATION_PASSWORD      | POSTGRES_REPLICATION_PASSWORD      |
| POSTGRESQL_REPLICATION_PASSWORD_FILE | POSTGRES_REPLICATION_PASSWORD_FILE |
| POSTGRESQL_CLUSTER_APP_NAME          | POSTGRES_CLUSTER_APP_NAME          |
| POSTGRESQL_MASTER_HOST               | POSTGRES_MASTER_HOST               |
| POSTGRESQL_MASTER_PORT_NUMBER        | POSTGRES_MASTER_PORT_NUMBER        |
| POSTGRESQL_NUM_SYNCHRONOUS_REPLICAS  | POSTGRES_NUM_SYNCHRONOUS_REPLICAS  |
| POSTGRESQL_SYNCHRONOUS_COMMIT_MODE   | POSTGRES_SYNCHRONOUS_COMMIT_MODE   |
| POSTGRESQL_SHUTDOWN_MODE             | POSTGRES_SHUTDOWN_MODE             |

> *IMPORTANT*: Changing the `POSTGRES_USER` will not change the owner of the database that will continue being the `postgres` user. In order to change the database owner, please access using `postgres` as user (`$ psql -U postgres ...`) and execute the following command:

```console
alter database POSTGRES_DATABASE owner to POSTGRES_USER;
```

It is possible to change the user that PostgreSQL will use to execute the init scripts. To do so, use the following environment variables:

| Environment variable            | Description                                                       |
|---------------------------------|-------------------------------------------------------------------|
| POSTGRESQL_INITSCRIPTS_USERNAME | User that will be used to execute the init scripts                |
| POSTGRESQL_INITSCRIPTS_PASSWORD | Password for the user specified in POSTGRESQL_INITSCRIPT_USERNAME |

### Default toast compression

The default toast compression is `pglz`, but you can modify it by setting the environment variable `POSTGRES_DEFAULT_COMPRESSION` with the desired value. For example: `POSTGRES_DEFAULT_COMPRESSION='lz4'`.

## Logging

The PostgreSQL Docker image sends the container logs to the `stdout`. To view the logs:

```console
docker logs postgresql
```

or using Docker Compose:

```console
docker-compose logs postgresql
```

You can configure the containers [logging driver](https://docs.docker.com/engine/admin/logging/overview/) using the `--log-driver` option if you wish to consume the container logs differently. In the default configuration docker uses the `json-file` driver.

## Maintenance

### Upgrade this image

Up-to-date versions of PostgreSQL are provided by Bitcompat project, including security patches, soon after they are made upstream. We recommend that you follow these steps to upgrade your container.

#### Step 1: Get the updated image

```console
docker pull ghcr.io/bitcompat/postgresql:latest
```

or if you're using Docker Compose, update the value of the image property to `ghcr.io/bitcompat/postgresql:latest`.

#### Step 2: Stop and backup the currently running container

Stop the currently running container using the command

```console
docker stop postgresql
```

or using Docker Compose:

```console
docker-compose stop postgresql
```

Next, take a snapshot of the persistent volume `/path/to/postgresql-persistence` using:

```console
rsync -a /path/to/postgresql-persistence /path/to/postgresql-persistence.bkp.$(date +%Y%m%d-%H.%M.%S)
```

#### Step 3: Remove the currently running container

```console
docker rm -v postgresql
```

or using Docker Compose:

```console
docker-compose rm -v postgresql
```

#### Step 4: Run the new image

Re-create your container from the new image.

```console
docker run --name postgresql ghcr.io/bitcompat/postgresql:latest
```

or using Docker Compose:

```console
docker-compose up postgresql
```

## Contributing

We'd love for you to contribute to this container. You can request new features by creating an [issue](https://github.com/bitcompat/postgresql/issues), or submit a [pull request](https://github.com/bitcompat/postgresql/pulls) with your contribution.

## Issues

If you encountered a problem running this container, you can file an [issue](https://github.com/bitcompat/postgresql/issues/new).

## License

This package is released under MIT license.

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
