use strict;
use lib 't/lib';
use SQLBackendTests;

# Table with generated columns and indexes as documented
run_tests(
    class  => 'Web::Session::MySQLJSON',
    driver => 'mysql',
    env    => 'MYSQL',
    table  => 'asb_test_mysqljson',
    create => [
            'CREATE TABLE __TABLE__ (id varchar(64) not null primary key,'
          . ' a_session json,'
          . ' as_wt varchar(255) COLLATE utf8mb4_bin'
          . " AS (a_session->>'\$._whatToTrace') VIRTUAL,"
          . ' as_sk varchar(32) COLLATE utf8mb4_bin'
          . " AS (a_session->>'\$._session_kind') VIRTUAL,"
          . ' as_ut bigint unsigned'
          . " AS (cast(a_session->>'\$._utime' as unsigned)) VIRTUAL,"
          . ' as_ls bigint unsigned'
          . " AS (cast(a_session->>'\$._lastSeen' as unsigned)) VIRTUAL,"
          . ' as_rt bigint unsigned'
          . " AS (cast(a_session->>'\$._oidcRtUpdate' as unsigned)) VIRTUAL,"
          . ' as_ip varchar(64) COLLATE utf8mb4_bin'
          . " AS (a_session->>'\$.ipAddr') VIRTUAL,"
          . ' KEY as_wt (as_wt), KEY as_sk (as_sk), KEY as_ut (as_ut),'
          . ' KEY as_ls (as_ls), KEY as_rt (as_rt), KEY as_ip (as_ip))'
          . ' ENGINE=InnoDB'
    ],
    null  => 1,
    json  => 1,
    weird => [ "weird'field", 'a"b\\c', 'a?b', 'x\\' ],
    exact => 1,
    utf8  => 1,
    explain => sub {
        my ( $class, $dbh ) = @_;
        my ( $wt, $sk ) =
          map { qq{a_session->>'\$.$_'} } qw(_whatToTrace _session_kind);
        my ( $ut, $ls ) =
          map { $class->_buildLowerThanExpression( $_, 200 ) }
          qw(_utime _lastSeen);
        my ( $rtlt, $rtgt ) = map {
            $class->_buildCompareExpression( '_oidcRtUpdate', $_, 200, $dbh )
        } qw(< >);
        return (
            [ 'deleteIfLowerThan', $ut, 'as_ut' ],
            [
                'deleteIfLowerThan with "not"',
                "($ut) AND ($sk IS NULL OR $sk <> 'Persistent')",
                'as_ut'
            ],
            [
                'deleteIfLowerThan "or" with "not"',
                "($ut OR $ls) AND ($sk IS NULL OR $sk <> 'Persistent')",
                [ 'as_ut', 'as_ls' ]
            ],
            [ 'searchOn', "$wt = 'dwho'", 'as_wt' ],
            [ 'searchLt', $rtlt,          'as_rt' ],
            [ 'searchGt', $rtgt,          'as_rt' ],
        );
    },
);
