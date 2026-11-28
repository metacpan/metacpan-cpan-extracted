use strict;
use lib 't/lib';
use SQLBackendTests;

# The PgJSON tests without the connection pool of
# Web::Session::Store::Postgres (KeepConnections => 0): sessions share the
# handle cached by DBI->connect_cached(), as before the pool became the
# default. Web-Session-PgJSON.t runs them with the pool
run_tests(
    class  => 'Web::Session::PgJSON',
    driver => 'Pg',
    env    => 'PG',
    table  => 'asb_test_pgjson_nopool',
    create => [
'CREATE TABLE __TABLE__ (id varchar(64) not null primary key, a_session jsonb)',
    ],
    args      => { KeepConnections => 0 },
    pool      => 0,
    null      => 1,
    json      => 1,
    weird     => [ "weird'field", 'a"b\\c', 'a?b', 'x\\' ],
    scs       => 1,
    tableCase => 1,
    todo      => {},
);
