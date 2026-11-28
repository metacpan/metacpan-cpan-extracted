use strict;
use lib 't/lib';
use SQLBackendTests;

# With Commit (set by run_tests), sessions use the connection pool of
# Web::Session::Store::Postgres by default. Web-Session-PgJSON-noPool.t runs
# the same tests with KeepConnections => 0
run_tests(
    class  => 'Web::Session::PgJSON',
    driver => 'Pg',
    env    => 'PG',
    pool   => 1,
    deferredInsert => 1,
    table  => 'asb_test_pgjson',
    create => [
'CREATE TABLE __TABLE__ (id varchar(64) not null primary key, a_session jsonb)',
        'CREATE INDEX __TABLE___uid1 ON __TABLE__ USING BTREE'
          . " ( (a_session ->> '_whatToTrace') text_pattern_ops )",
        'CREATE INDEX __TABLE___u1 ON __TABLE__'
          . " ( ( cast(a_session ->> '_utime' AS bigint) ) )",
        'CREATE INDEX __TABLE___ls1 ON __TABLE__'
          . " ( ( cast(a_session ->> '_lastSeen' AS bigint) ) )",
        'CREATE INDEX __TABLE___rt1 ON __TABLE__'
          . " ( ( cast(a_session ->> '_oidcRtUpdate' AS bigint) ) )",
        'CREATE INDEX __TABLE___gin ON __TABLE__'
          . ' USING GIN (a_session jsonb_path_ops)',
    ],
    gin   => 1,
    null  => 1,
    json  => 1,
    weird => [ "weird'field", 'a"b\\c', 'a?b', 'x\\' ],
    scs   => 1,
    tableCase => 1,
    todo => {
    },
    explain => sub {
        my ($class) = @_;
        my ( $ut, $ls ) =
          map { $class->_buildLowerThanExpression( $_, 200 ) }
          qw(_utime _lastSeen);
        my ( $rtlt, $rtgt ) =
          map { $class->_buildCompareExpression( '_oidcRtUpdate', $_, 200 ) }
          qw(< >);
        my ( $wt, $sk ) =
          map { "a_session ->> '$_'" } qw(_whatToTrace _session_kind);

        # The statement deleteIfLowerThan() really runs, one batch
        my $batch = sub {
            my ( $table, $where ) = @_;
            return $class->_deleteBatchStatement( $table, $where, 1000 );
        };
        my $purge = "($ut OR $ls) AND ($sk IS NULL OR $sk <> 'Persistent')";
        return (
            [ 'deleteIfLowerThan', $ut, '__TABLE___u1' ],
            [
                'deleteIfLowerThan "or" with "not"', $purge,
                [ '__TABLE___u1', '__TABLE___ls1' ]
            ],
            [ 'deleteIfLowerThan batch', $ut, '__TABLE___u1', $batch ],
            [
                'deleteIfLowerThan batch, "or" with "not"', $purge,
                [ '__TABLE___u1', '__TABLE___ls1' ], $batch
            ],
            [ 'searchOnExpr', "$wt like 'dw%'", '__TABLE___uid1' ],
            [ 'searchOn',     "$wt = 'dwho'",   '__TABLE___uid1' ],
            [ 'searchLt',     $rtlt,            '__TABLE___rt1' ],
            [ 'searchGt',     $rtgt,            '__TABLE___rt1' ],
        );
    },
);
