[![Build Status](https://circleci.com/gh/TJC/Test-postgresql.svg)](https://circleci.com/gh/TJC/Test-postgresql)
# NAME

Test::PostgreSQL - PostgreSQL runner for tests

# SYNOPSIS

    use DBI;
    use Test::PostgreSQL;
    use Test::More;

    # optionally
    # (if not already set at shell):
    #
    # $ENV{POSTGRES_HOME} = '/path/to/my/pgsql/installation';

    my $pgsql = eval { Test::PostgreSQL->new() }
        or plan skip_all => $@;

    plan tests => XXX;

    my $dbh = DBI->connect($pgsql->dsn);

# DESCRIPTION

`Test::PostgreSQL` automatically setups a PostgreSQL instance in a temporary
directory, and destroys it when the perl script exits.

This module is a fork of Test::postgresql, which was abandoned by its author
several years ago.

# ATTRIBUTES

`Test::PostgreSQL` object has the following attributes, overridable by passing
corresponding argument to constructor:

## dbname

Database name to use in this `Test::PostgreSQL` instance. Default is `test`.

## dbowner

Database owner user name. Default is `postgres`.

## host

Host name or IP address to use for PostgreSQL instance connections. Default is
`127.0.0.1`.

## base\_dir

Base directory under which the PostgreSQL instance is being created. The
property can be passed as a parameter to the constructor, in which case the
directory will not be removed at exit.

## base\_port

Connection port number to start with. If the port is already used we will increment
the value and try again.

Default: `15432`.

## unix\_socket

Whether to only connect via UNIX sockets; if false (the default),
connections can occur via localhost. \[This changes the ["dsn"](#dsn)
returned to only give the UNIX socket directory, and avoids any issues with
conflicting TCP ports on localhost.\]

## socket\_dir

Unix socket directory to use if ["unix\_socket"](#unix_socket) is true. Default is `$basedir/tmp`.

## pg\_ctl

Path to `pg_ctl` program which is part of the PostgreSQL distribution.

Starting with PostgreSQL version 9.0 `pg_ctl` can be used to start/stop
postgres without having to use fork/pipe and will be chosen automatically
if ["pg\_ctl"](#pg_ctl) is not set but the program is found and the version is recent
enough.

**NOTE:** do NOT use this with PostgreSQL versions prior to version 9.0.

By default we will try to find `pg_ctl` in PostgresSQL directory.

## initdb

Path to `initdb` program which is part of the PostreSQL distribution. Default is
to try and find it in PostgreSQL directory.

## initdb\_args

Arguments to pass to `initdb` program when creating a new PostgreSQL database
cluster for Test::PostgreSQL session.

Defaults to `-U postgres -A trust`. See ["db\_owner"](#db_owner).

## extra\_initdb\_args

Extra args to be appended to ["initdb\_args"](#initdb_args). Default is empty.

## pg\_config

Configuration to place in `$basedir/data/postgresql.conf`. Use this to override
PostgreSQL configuration defaults, e.g. to speed up PostgreSQL database init
and seeding one might use something like this:

    my $pgsql = Test::PostgreSQL->new(
        pg_config => q|
        # foo baroo mymse throbbozongo
        fsync = off
        synchronous_commit = off
        full_page_writes = off
        bgwriter_lru_maxpages = 0
        shared_buffers = 512MB
        effective_cache_size = 512MB
        work_mem = 100MB
    |);

## postmaster

Path to `postmaster` which is part of the PostgreSQL distribution. If not set,
the programs are automatically searched by looking up $PATH and other prefixed
directories. Since `postmaster` is deprecated in newer PostgreSQL versions
`postgres` is used in preference to `postmaster`.

## postmaster\_args

Defaults to `-h 127.0.0.1 -F`.

## extra\_postmaster\_args

Extra args to be appended to ["postmaster\_args"](#postmaster_args). Default is empty.

## psql

Path to `psql` client which is part of the PostgreSQL distribution.

`psql` can be used to run SQL scripts against the temporary database created
by ["new"](#new):

    my $pgsql = Test::PostgreSQL->new();
    my $psql = $pgsql->psql;
    
    my $out = `$psql -f /path/to/script.sql 2>&1`;
    
    die "Error executing script.sql: $out" unless $? == 0;

## psql\_args

Command line arguments necessary for `psql` to connect to the correct PostgreSQL
instance.

Defaults to `-U postgres -d test -h 127.0.0.1 -p $self->port`.

See also ["db\_owner"](#db_owner), ["dbname"](#dbname), ["host"](#host), ["base\_port"](#base_port).

## extra\_psql\_args

Extra args to be appended to ["psql\_args"](#psql_args).

## run\_psql\_args

Arguments specific for ["run\_psql"](#run_psql) invocation, used mostly to set up and seed
database schema after PostgreSQL instance is launched and configured.

Default is `-1Xqb -v ON_ERROR_STOP=1`. This means:

- 1: Run all SQL statements in passed scripts as single transaction
- X: Skip `.psqlrc` files
- q: Run quietly, print only notices and errors on stderr (if any)
- b: Echo SQL statements that cause PostgreSQL exceptions (version 9.5+)
- -v ON\_ERROR\_STOP=1: Stop processing SQL statements after the first error

## seed\_scripts

Arrayref with the list of SQL scripts to run after the database was instanced
and set up. Default is `[]`.

**NOTE** that `psql` older than 9.6 does not support multiple `-c` and `-f`
switches in arguments so `seed_scripts` will be executed one by one. This
implies multiple transactions instead of just one; if you need all seed statements
to apply within a single transaction, combine them into one seed script.

## auto\_start

Integer value that controls whether PostgreSQL server is started and setup
after creating `Test::PostgreSQL` instance. Possible values:

- `0`

    Do not start PostgreSQL.

- `1`

    Start PostgreSQL but do not run ["setup"](#setup).

- `2`

    Start PostgreSQL and run ["setup"](#setup).

    Default is `2`.

# METHODS

## new

Create and run a PostgreSQL instance. The instance is terminated when the
returned object is being DESTROYed.  If required programs (initdb and
postmaster) were not found, the function returns undef and sets appropriate
message to $Test::PostgreSQL::errstr.

## dsn

Builds and returns dsn by using given parameters (if any).  Default username is
`postgres`, and dbname is `test` (an empty database).

## uri

Builds and returns a connection URI using the given parameters (if any). See
[URI::db](https://metacpan.org/pod/URI::db) for details about the format.

Default username is `postgres`, and dbname is `test` (an empty database).

## pid

Returns process id of PostgreSQL (or undef if not running).

## port

Returns TCP port number on which postmaster is accepting connections (or undef
if not running).

## start

Starts postmaster.

## stop

Stops postmaster.

## setup

Setups the PostgreSQL instance. Note that this method should be invoked _before_
["start"](#start).

## run\_psql

Execute `psql` program with the given list of arguments. Usually this would be
something like:

    $pgsql->run_psql('-c', q|'INSERT INTO foo (bar) VALUES (42)'|);

Or:

    $pgsql->run_psql('-f', '/path/to/script.sql');

Note that when using literal SQL statements with `-c` parameter you will need
to escape them manually like shown above. `run_psql` will not quote them for you.

The actual command line to execute `psql` will be concatenated from ["psql\_args"](#psql_args),
["extra\_psql\_args"](#extra_psql_args), and ["run\_psql\_args"](#run_psql_args).

**NOTE** that `psql` older than 9.6 does not support multiple `-c` and/or `-f`
switches in arguments.

## run\_psql\_scripts

Given a list of script file paths, invoke ["run\_psql"](#run_psql) once with `-f 'script'`
for every path in PostgreSQL 9.6+, or once per `-f 'script'` for older PostgreSQL
versions.

# ENVIRONMENT

## POSTGRES\_HOME

If your postgres installation is not located in a well known path, or you have
many versions installed and want to run your tests against particular one, set
this environment variable to the desired path. For example:

    export POSTGRES_HOME='/usr/local/pgsql94beta'

This is the same idea and variable name which is used by the installer of
[DBD::Pg](https://metacpan.org/pod/DBD::Pg).

# AUTHOR

Toby Corkindale, Kazuho Oku, Peter Mottram, Alex Tokarev, plus various contributors.

# COPYRIGHT

Current version copyright © 2012-2015 Toby Corkindale.

Previous versions copyright (C) 2009 Cybozu Labs, Inc.

# LICENSE

This module is free software, released under the Perl Artistic License 2.0.
See [http://www.perlfoundation.org/artistic\_license\_2\_0](http://www.perlfoundation.org/artistic_license_2_0) for more information.
