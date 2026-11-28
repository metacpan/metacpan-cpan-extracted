use strict;
use Test::More;
use lib 't/lib';
use SQLBackendTests;

# Works with DBD::MariaDB (dbi:MariaDB:...) and DBD::mysql (dbi:mysql:...)
plan skip_all => 'Set MARIADB_DSN to run this test' unless $ENV{MARIADB_DSN};

# Indexed field with a non-ASCII name, kept in UTF-8 so that DBD::mysql sends
# UTF-8 bytes as well
my $accented = "cl\x{e9}";
utf8::upgrade($accented);

# Table with generated columns and indexes as documented, plus generated
# columns with names that need quoting
subtest 'Generated columns' => sub {
    run_tests(
        class  => 'Web::Session::MariaDBJSON',
        env    => 'MARIADB',
        table  => 'asb_test_mariadbjson',
        create => [
                'CREATE TABLE __TABLE__ (id varchar(64) not null primary key,'
              . ' a_session json,'
              . ' _whatToTrace varchar(255) COLLATE utf8mb4_bin'
              . " AS (JSON_VALUE(a_session, '\$._whatToTrace')) VIRTUAL,"
              . ' _session_kind varchar(32) COLLATE utf8mb4_bin'
              . " AS (JSON_VALUE(a_session, '\$._session_kind')) VIRTUAL,"
              . ' _utime bigint unsigned'
              . " AS (cast(JSON_VALUE(a_session, '\$._utime') as unsigned))"
              . ' VIRTUAL,'
              . ' _lastSeen bigint unsigned'
              . " AS (cast(JSON_VALUE(a_session, '\$._lastSeen') as unsigned))"
              . ' VIRTUAL,'
              . ' _oidcRtUpdate bigint unsigned AS'
              . " (cast(JSON_VALUE(a_session, '\$._oidcRtUpdate') as unsigned))"
              . ' VIRTUAL,'
              . ' ipAddr varchar(64) COLLATE utf8mb4_bin'
              . " AS (JSON_VALUE(a_session, '\$.ipAddr')) VIRTUAL,"
              . " `weird'field` varchar(8) COLLATE utf8mb4_bin"
              . " AS (JSON_VALUE(a_session, '\$.\"weird''field\"')) PERSISTENT,"
              . " `$accented` varchar(64) COLLATE utf8mb4_bin"
              . " AS (JSON_VALUE(a_session, '\$.\"$accented\"')) VIRTUAL,"
              . ' KEY _whatToTrace (_whatToTrace),'
              . ' KEY _session_kind (_session_kind), KEY _utime (_utime),'
              . ' KEY _lastSeen (_lastSeen), KEY _oidcRtUpdate (_oidcRtUpdate),'
              . " KEY ipAddr (ipAddr), KEY weird (`weird'field`),"
              . " KEY `$accented` (`$accented`)) ENGINE=InnoDB"
        ],
        index => "_whatToTrace _session_kind _utime _lastSeen _oidcRtUpdate"
          . " ipAddr weird'field $accented",
        json  => 1,
        null  => 1,
        utf8  => 1,
        exact => 1,
        weird => [ "weird'field", 'a"b\\c', 'a?b', 'x\\', 'a.b', $accented ],
        explain_key  => 1,
        explain_fill => 100,
        explain      => sub {
            my ( $class, $dbh, $args ) = @_;
            my ( $wt, $sk, $wf ) =
              map { $class->_sqlField( $dbh, $_, $args ) }
              ( '_whatToTrace', '_session_kind', "weird'field" );
            my ( $ut, $ls ) =
              map { $class->_buildLowerThanExpression( $_, 200, $dbh, $args ) }
              qw(_utime _lastSeen);
            my ( $rtlt, $rtgt ) = map {
                $class->_buildCompareExpression( '_oidcRtUpdate', $_, 200,
                    $dbh, $args )
            } qw(< >);
            my $not = "($sk IS NULL OR $sk <> 'Persistent')";
            return (
                [ 'searchOn',     "$wt = 'dwho'",            '_whatToTrace' ],
                [ 'searchOnExpr', "$wt LIKE 'dw%'",          '_whatToTrace' ],
                [ 'searchOn on quoted column', "$wf = 'w1'", 'weird' ],
                [ 'deleteIfLowerThan',         $ut, '_utime', 'DELETE' ],
                [
                    'deleteIfLowerThan with "not"', "($ut) AND $not",
                    '_utime',                       'DELETE'
                ],
                [
                    'deleteIfLowerThan "or" with "not"',
                    "($ut OR $ls) AND $not",
                    [ '_utime', '_lastSeen' ],
                    'DELETE'
                ],
                [ 'searchLt', $rtlt, '_oidcRtUpdate' ],
                [ 'searchGt', $rtgt, '_oidcRtUpdate' ],
            );
        },
    );
};

# Without generated columns: every field is read with JSON_VALUE
subtest 'JSON_VALUE only' => sub {
    run_tests(
        class  => 'Web::Session::MariaDBJSON',
        env    => 'MARIADB',
        table  => 'asb_test_mariadbjson_plain',
        create => [
                'CREATE TABLE __TABLE__ (id varchar(64) not null primary key,'
              . ' a_session json) ENGINE=InnoDB'
        ],
        json  => 1,
        null  => 1,
        utf8  => 1,
        exact => 1,
        weird => [ "weird'field", 'a"b\\c', 'a?b', 'x\\', 'a.b' ],
    );
};

done_testing();
