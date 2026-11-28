# Web::Session

[![Build Status](https://github.com/linagora/perl-Web-Session/actions/workflows/ci.yml/badge.svg)](https://github.com/linagora/perl-Web-Session/actions/workflows/ci.yml)

Web::Session is a fork of
[Apache::Session::Browseable](https://metacpan.org/dist/Apache-Session-Browseable),
which itself extends [Apache::Session](https://metacpan.org/dist/Apache-Session):
sessions are stored in a database and can be searched, listed and purged
through indexes (`searchOn()`, `searchOnExpr()`, `searchLt()`, `searchGt()`,
`get_key_from_all_sessions()`, `deleteIfLowerThan()`).

- **Fully compatible with Apache::Session**: every backend is an
  Apache::Session implementation (`tie %session, 'Web::Session::PgJSON', $id, $args`).
- **Includes many fixes still pending in Apache::Session::Browseable**: SQL
  injections, `deleteIfLowerThan()` rules, UTF-8 handling, Redis index
  cleanup, identifier quoting, performance of full scans, connection reuse...
- **Better tested**: the backends are tested in CI against real servers
  (PostgreSQL, MySQL, two MariaDB versions, Redis, OpenLDAP), with a shared
  SQL test suite and `EXPLAIN` checks that the documented indexes are really
  used.
- **Open to AI-assisted contributions**: pull requests written with the help
  of AI tools are welcome, as long as they come with tests and are reviewed
  like any other contribution.

It has been written to increase the performance of
[LemonLDAP::NG](https://lemonldap-ng.org).

## Backends

| Database   | Module                                              |
|------------|-----------------------------------------------------|
| PostgreSQL | `Web::Session::PgJSON` (alias: `Web::Session::Postgres`), `Web::Session::Patroni` |
| MySQL      | `Web::Session::MySQLJSON` (alias: `Web::Session::MySQL`) |
| MariaDB    | `Web::Session::MariaDBJSON` (alias: `Web::Session::MariaDB`) |
| SQLite     | `Web::Session::SQLite`                              |
| Redis      | `Web::Session::Redis`                               |
| Cassandra  | `Web::Session::Cassandra`                           |
| LDAP       | `Web::Session::LDAP`                                |
| Files      | `Web::Session::File`                                |

Read the documentation of the chosen module to create the table and the
indexes: `perldoc Web::Session::PgJSON`, for example.

## Example

```perl
use Web::Session::PgJSON;

my $args = {
    DataSource => 'dbi:Pg:dbname=sessions',
    UserName   => $user,
    Password   => $password,
    Commit     => 1,    # needed by the connection pool (default)
};

# Use it like Apache::Session
tie my %session, 'Web::Session::PgJSON', undef, $args;
$session{uid} = 'dwho';
my $id = $session{_session_id};
untie %session;

# Search sessions
my $sessions =
  Web::Session::PgJSON->searchOn( $args, 'uid', 'dwho', '_utime' );

# Purge old sessions
Web::Session::PgJSON->deleteIfLowerThan( $args,
    { or => { _utime => time - 7200 } } );
```

## Migrating from Apache::Session::Browseable

- Replace `Apache::Session::Browseable::` by `Web::Session::` in module
  names (LemonLDAP::NG: `globalStorage`, `persistentStorage`...).
- `Postgres` and `MySQL` are now aliases of `PgJSON` and `MySQLJSON`:
  sessions are stored as JSON, indexes are expression indexes or generated
  columns. Tables created for the former column backends must be converted
  (see `perldoc Web::Session::Postgres` and `perldoc Web::Session::MySQL`).
- The Oracle, Informix, Sybase and PgHstore backends were removed.
- `Apache::Session::Serialize::JSON` and `Apache::Session::Generate::SHA256`
  are now `Web::Session::Serialize::JSON` and `Web::Session::Generate::SHA256`.

See [Changes](Changes) for the full list of changes.

## Installation

```
perl Build.PL
./Build
./Build test
./Build install
```

Run the tests through `./Build test` (or `prove -b` after `./Build`), not
`prove -l`: some modules use AutoLoader, and their autosplit files exist only
in `blib/`.

Tests of database backends run only when the database is available: see
`t/lib/SQLBackendTests.pm` and `.github/workflows/ci.yml` for the
environment variables (`PG_DSN`, `MYSQL_DSN`, `MARIADB_DSN`, `REDIS_URL`,
`LDAP_URL`...).

## License

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself, either Perl version 5.10.1 or, at your option,
any later version of Perl 5 you may have available. See [COPYRIGHT](COPYRIGHT)
and [LICENSE](LICENSE).
