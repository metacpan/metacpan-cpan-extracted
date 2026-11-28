use strict;
use warnings;
no warnings 'once';
use Test::More;

# Web::Session::Patroni sessions with the connection pool, against the
# PostgreSQL server of PG_DSN: the Patroni API is mocked and gives this
# server as leader, the configured DataSource points to a closed port
plan skip_all => 'PG_DSN not set' unless $ENV{PG_DSN};
plan skip_all => 'DBI, DBD::Pg, JSON, LWP::Protocol::PSGI and '
  . 'IO::Socket::SSL are needed for this test'
  unless eval {
    require DBI;
    require DBD::Pg;
    require JSON;
    require LWP::Protocol::PSGI;
    require IO::Socket::SSL;
    1;
  };

use_ok('Web::Session::Patroni');

my ($host) = $ENV{PG_DSN} =~ /host=([^;]+)/;
my ($port) = $ENV{PG_DSN} =~ /port=(\d+)/;
my ($db)   = $ENV{PG_DSN} =~ /dbname=([^;]+)/;
$host ||= '127.0.0.1';
$port ||= 5432;
$db   ||= 'sessions';
my $user  = $ENV{PG_USER};
my $table = 'asb_test_patroni_pool';

my $dbh =
  DBI->connect( $ENV{PG_DSN}, $user, $ENV{PG_PASSWORD},
    { RaiseError => 1, AutoCommit => 1, PrintError => 0 } );
$dbh->do("DROP TABLE IF EXISTS $table");
$dbh->do("CREATE TABLE $table (id varchar(64) not null primary key,"
      . ' a_session jsonb)' );

my $apiCalls = 0;
my $guard    = LWP::Protocol::PSGI->register(
    sub {
        $apiCalls++;
        return [
            200,
            [ 'Content-Type' => 'application/json' ],
            [
                JSON::to_json(
                    {
                        members => [
                            {
                                role  => 'leader',
                                host  => $host,
                                port  => $port,
                                state => 'running'
                            }
                        ]
                    }
                )
            ]
        ];
    }
);

my $configured = "dbi:Pg:dbname=$db;host=127.0.0.1;port=1";
my $leaderDsn  = "dbi:Pg:dbname=$db;host=$host;port=$port";
my $key        = "$leaderDsn\0" . ( $user // '' );

sub args {
    return {
        DataSource => $configured,
        UserName   => $user,
        Password   => $ENV{PG_PASSWORD},
        TableName  => $table,
        Commit     => 1,
        PatroniUrl => 'http://patroni:8008/cluster',
    };
}

sub idle { $Web::Session::Store::Postgres::IDLE{$key} || [] }

my $id;
{
    my $stderr = '';
    local *STDERR;
    open STDERR, '>', \$stderr;
    local $SIG{__WARN__} = sub { $stderr .= $_[0] };
    my %h;
    tie %h, 'Web::Session::Patroni', undef, args();
    $id = $h{_session_id};
    $h{a} = 'aa';
    untie %h;
}
ok( $id, 'Session created through the Patroni API' );
is( $apiCalls,      1, 'Patroni API called once' );
is( scalar @{ idle() }, 1, 'Connection to the leader given back to the pool' );
my $pooled = idle()->[0]->[0];

{
    my %h;
    tie %h, 'Web::Session::Patroni', $id, args();
    is( $h{a}, 'aa', 'Data stored' );
    $h{a} = 'bb';
    untie %h;
}
{
    my %h;
    tie %h, 'Web::Session::Patroni', $id, args();
    is( $h{a}, 'bb', 'Data updated' );
    untie %h;
}
is( $apiCalls,          1,       'Leader cache: no more API calls' );
is( scalar @{ idle() }, 1,       'Still one idle connection' );
is( idle()->[0]->[0],   $pooled, 'Same connection reused' );

# The row read by a tie stays locked until untie (SELECT ... FOR UPDATE in
# the transaction of the tie): a concurrent update of the same session waits
{
    my $other = DBI->connect(
        $ENV{PG_DSN},
        $user,
        $ENV{PG_PASSWORD},
        { RaiseError => 1, AutoCommit => 1, PrintError => 0 }
    );
    $other->do("SET lock_timeout = '500ms'");
    my $lock = sub {
        eval {
            $other->do( "SELECT 1 FROM $table WHERE id = ? FOR UPDATE",
                undef, $id );
            1;
        };
    };
    my %h;
    tie %h, 'Web::Session::Patroni', $id, args();
    ok( !$lock->(), 'Tied session: row locked' );
    like( $@, qr/lock/i, 'Tied session: lock timeout' );
    is( scalar @{ idle() }, 0, 'Tied session: connection lent' );
    $h{a} = 'cc';
    untie %h;
    ok( $lock->(), 'Untied session: row unlocked' ) or diag $@;
    $other->disconnect;
}
{
    my %h;
    tie %h, 'Web::Session::Patroni', $id, args();
    is( $h{a}, 'cc', 'Update committed at untie' );
    untie %h;
}
is( scalar @{ idle() }, 1, 'Connection given back after the transaction' );
ok( idle()->[0]->[0]->{AutoCommit}, 'Given back with AutoCommit on' );

{
    my %h;
    tie %h, 'Web::Session::Patroni', $id, args();
    tied(%h)->delete;
    untie %h;
}
is( $dbh->selectrow_array("SELECT count(*) FROM $table"), 0,
    'Session removed' );

$dbh->do("DROP TABLE $table");
done_testing();
