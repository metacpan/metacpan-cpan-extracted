use strict;
use warnings;
no warnings 'once';
use Test::More;

# Web::Session::Store::Patroni with the connection pool of
# Web::Session::Store::Postgres, without database: DBI connections and the
# Patroni API are mocked
plan skip_all => 'DBI, Apache::Session, JSON, LWP::Protocol::PSGI and '
  . 'IO::Socket::SSL are needed for this test'
  unless eval {
    require DBI;
    require Apache::Session::Store::Postgres;
    require JSON;
    require LWP::Protocol::PSGI;
    require IO::Socket::SSL;
    1;
  };

{

    package FakeDbh;
    our ( @connects, @sql, $disconnects, %readonly, %down, $failCommit );

    sub new {
        my ( $class, $ds, %attr ) = @_;
        return bless {
            Active => 1,
            Driver => { Name => 'Pg' },
            Type   => 'db',
            Name   => $ds,
            %attr,
        }, $class;
    }

    # A demoted primary still answers ping()
    sub ping { $_[0]->{Active} }

    sub disconnect {
        $_[0]->{Active} = 0;
        $disconnects++;
        return 1;
    }

    # Statement handles inherit HandleError, as with DBI
    sub prepare_cached {
        my ( $self, $sql ) = @_;
        return bless {
            sql         => $sql,
            Type        => 'st',
            Database    => $self,
            HandleError => $self->{HandleError},
        }, 'FakeSth';
    }
    *prepare = \&prepare_cached;
    # As DBI: begin_work turns AutoCommit off until commit() or rollback()
    sub begin_work {
        my ($self) = @_;
        die "Already in a transaction\n" unless ( $self->{AutoCommit} );
        push @FakeDbh::sql, "BEGIN ON $self->{Name}";
        $self->{AutoCommit} = 0;
        $self->{BegunWork}  = 1;
        return 1;
    }

    sub _end {
        my ( $self, $what ) = @_;
        push @FakeDbh::sql, "$what ON $self->{Name}";
        $self->{AutoCommit} = 1 if ( delete $self->{BegunWork} );
        return 1;
    }

    sub commit {
        die "commit failed\n" if ($FakeDbh::failCommit);
        return $_[0]->_end('COMMIT');
    }
    sub rollback { $_[0]->_end('ROLLBACK') }

    package FakeSth;
    sub bind_param { 1 }

    # On a node that is no longer the primary, every write fails (and
    # SELECT ... FOR UPDATE too)
    sub execute {
        my ($self) = @_;
        my $db = $self->{Database};
        push @FakeDbh::sql, "$self->{sql} ON $db->{Name}";
        if ( $FakeDbh::readonly{ $db->{Name} }
            and $self->{sql} =~ /INSERT|UPDATE|DELETE/ )
        {
            my $err = 'cannot execute UPDATE in a read-only transaction';
            $self->{HandleError}->( $err, $self, undef )
              if ( $self->{HandleError} );
            die "$err\n";
        }
        return 1;
    }
    sub fetchrow_arrayref { ['{}'] }
    sub finish            { 1 }
}

my $class = 'Web::Session::Store::Patroni';
use_ok($class);

my $ds    = 'dbi:Pg:dbname=sessions';
my $node1 = "$ds;host=10.0.0.1;port=5432";
my $node2 = "$ds;host=10.0.0.2;port=5432";

no warnings 'redefine';
local *DBI::connect = sub {
    my ( undef, $dsn, $user, $pass, $attr ) = @_;
    die "could not connect to $dsn\n" if ( $FakeDbh::down{$dsn} );
    my $dbh = FakeDbh->new( $dsn, %$attr );
    push @FakeDbh::connects, [ $dsn, $attr, $dbh ];
    return $dbh;
};
local *DBI::connect_cached = sub {
    my ( undef, $dsn, $user, $pass, $attr ) = @_;
    die "could not connect to $dsn\n" if ( $FakeDbh::down{$dsn} );
    my $dbh = FakeDbh->new( $dsn, %$attr );
    push @FakeDbh::connects, [ $dsn, $attr, $dbh, 'cached' ];
    return $dbh;
};
use warnings 'redefine';

# Mocked Patroni API: the leader is $leader
my $leader   = '10.0.0.1';
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
                            map {
                                {
                                    role => $_ eq $leader
                                    ? 'leader'
                                    : 'replica',
                                    host  => $_,
                                    port  => 5432,
                                    state => 'running'
                                }
                            } qw(10.0.0.1 10.0.0.2)
                        ]
                    }
                )
            ]
        ];
    }
);

my %base = (
    DataSource => $ds,
    UserName   => 'u',
    Commit     => 1,
    PatroniUrl => 'http://patroni:8008/cluster',
);
my $n = 0;

# A session with a copy of the arguments, as each tie
sub session {
    my %args = ( %base, @_ );
    return {
        args       => \%args,
        data       => { _session_id => 'id' . ++$n },
        serialized => '{}',
    };
}

sub reset_all {
    %Web::Session::Store::Postgres::IDLE         = ();
    %Web::Session::Store::Postgres::DROPS        = ();
    %Web::Session::Store::Patroni::patroniCache = ();
    @FakeDbh::connects                           = ();
    @FakeDbh::sql                                = ();
    %FakeDbh::readonly                           = ();
    %FakeDbh::down                               = ();
    $FakeDbh::disconnects                        = 0;
    $FakeDbh::failCommit                         = 0;
    $leader                                      = '10.0.0.1';
    $apiCalls                                    = 0;
}

sub idle {
    my ($dsn) = @_;
    return scalar @{ $Web::Session::Store::Postgres::IDLE{"$dsn\0u"} || [] };
}

# First word of the statements run on $dsn (and BEGIN, COMMIT, ROLLBACK)
sub statements {
    my ($dsn) = @_;
    return map { /^\s*(\w+)/ ? $1 : () }
      grep { / ON \Q$dsn\E$/ } @FakeDbh::sql;
}

# Whether all idle connections to $dsn have AutoCommit on (no transaction)
sub idle_autocommit {
    my ($dsn) = @_;
    return !grep { !$_->[0]->{AutoCommit} }
      @{ $Web::Session::Store::Postgres::IDLE{"$dsn\0u"} || [] };
}

# Patroni messages on STDERR
sub quiet(&) {
    my ($code) = @_;
    my $stderr = '';
    local *STDERR;
    open STDERR, '>', \$stderr;
    local $SIG{__WARN__} = sub { $stderr .= $_[0] };
    return $code->();
}

# The configured node is down: the primary is found by the Patroni API, and
# the connection to it comes from the pool
reset_all();
$FakeDbh::down{$ds} = 1;
{
    my $store = $class->new;
    quiet { $store->insert( session() ) };
    is( $apiCalls, 1, 'Connection failure: Patroni API called' );
    is( scalar @FakeDbh::connects, 1, 'One connection opened' );
    is( $FakeDbh::connects[0]->[0], $node1, 'To the primary' );
    ok( !$FakeDbh::connects[0]->[3], 'Not connect_cached()' );
    ok( $FakeDbh::connects[0]->[1]->{AutoCommit}, 'AutoCommit on' );
    is( ref( $FakeDbh::connects[0]->[1]->{HandleError} ),
        'CODE', 'HandleError set' );
    is( $store->{pool_key}, "$node1\0u", 'Pool keyed by the primary DSN' );
}
is( idle($node1), 1, 'Connection given back to the pool' );
is( $FakeDbh::disconnects, 0, 'Connection not closed' );
is_deeply( [ statements($node1) ], [qw(BEGIN INSERT COMMIT)],
    'One transaction per tie: BEGIN, INSERT, COMMIT' );
ok( idle($node1) && idle_autocommit($node1),
    'Given back with AutoCommit on' );

# The next sessions (leader cache) reuse it
{
    my $store = $class->new;
    $store->update( session() );
    is( scalar @FakeDbh::connects, 1,      'Next tie: connection reused' );
    is( $store->{dbh}->{Name},     $node1, 'Next tie: to the primary' );
    is( idle($node1),              0,      'Lent: no longer idle' );
}
{
    my $s     = session();
    my $store = $class->new;
    $store->materialize($s);
    $store->update($s);
    is( scalar @FakeDbh::connects, 1, 'Third tie: connection reused' );
}
is( $apiCalls, 1, 'Leader cache: no more API calls' );

# Two stores at once never share a connection
{
    my ( $s1, $s2 ) = ( $class->new, $class->new );
    $s1->update( session() );
    $s2->update( session() );
    isnt( $s1->{dbh}, $s2->{dbh}, 'Two stores at once: two connections' );
}
is( idle($node1), 2, 'Both given back' );

# A session keeps a connection to 10.0.0.1 during the failover below
my $lent = $class->new;
$lent->update( session() );
my $lentDbh = $lent->{dbh};

# Failover: 10.0.0.1 is demoted (it still answers ping, writes fail), the
# Patroni API now gives 10.0.0.2
$leader = '10.0.0.2';
$FakeDbh::readonly{$node1} = 1;
my @old = map { $_->[0] } @{ $Web::Session::Store::Postgres::IDLE{"$node1\0u"} };
{
    my $store = $class->new;
    quiet { $store->update( session() ) };
    is( $apiCalls, 2, 'Failover: write failure, Patroni API called' );
    is( $store->{dbh}->{Name}, $node2, 'Failover: connected to the new primary' );
    is( $FakeDbh::connects[-1]->[0], $node2, 'Failover: new connection' );
    like( $FakeDbh::sql[-1], qr/^\s*UPDATE.* ON \Q$node2\E$/s,
        'Failover: update done on the new primary' );
}
is( idle($node1), 0, 'Failover: no idle connection to the former primary' );
ok( !( grep { $_->{Active} } @old ),
    'Failover: connections to the former primary closed' );
is( idle($node2), 1, 'New primary connection given back to the pool' );
ok( grep( { $_ eq "ROLLBACK ON $node1" } @FakeDbh::sql ),
    'Failover: transaction of the failed statement rolled back' );
is_deeply(
    [ ( statements($node2) )[ -3 .. -1 ] ],
    [qw(BEGIN UPDATE COMMIT)],
    'Failover: statement retried in a new transaction'
);
ok( idle_autocommit($node2), 'Failover: idle connections have AutoCommit on' );

# Lent to another session at the time of the failover: closed when given
# back, not kept with the idle connections of the former primary
undef $lent;
is( idle($node1), 0, 'Failover: lent connection not given back' );
ok( !$lentDbh->{Active}, 'Failover: lent connection closed when given back' );

# Dropping idle connections doesn't disconnect a closed handle again
{
    my $closed =
      FakeDbh->new( $node1, private_ws_pid => $$, private_ws_born => time );
    $closed->{Active} = 0;
    push @{ $Web::Session::Store::Postgres::IDLE{"$node1\0u"} },
      [ $closed, time ];
    my $disconnects = $FakeDbh::disconnects;
    Web::Session::Store::Postgres::_dropIdle("$node1\0u");
    is( $FakeDbh::disconnects, $disconnects,
        'Dropped: closed handle not disconnected again' );
}

# The next sessions use the new primary (leader cache under the original
# DataSource) and its pooled connection
{
    my $connects = @FakeDbh::connects;
    my $store    = $class->new;
    $store->update( session() );
    is( $store->{dbh}->{Name}, $node2, 'After failover: new primary used' );
    is( scalar @FakeDbh::connects, $connects,
        'After failover: pooled connection reused' );
    is( $apiCalls, 2, 'After failover: no API call' );
}

# A connection to the former primary given back late (lent during the
# failover) is never lent again: it belongs to another pool key
{
    push @{ $Web::Session::Store::Postgres::IDLE{"$node1\0u"} },
      [ FakeDbh->new( $node1, private_ws_pid => $$, private_ws_born => time ),
        time ];
    my $store = $class->new;
    $store->update( session() );
    is( $store->{dbh}->{Name}, $node2,
        'Late connection to the former primary not lent' );
}

# Transactions on pooled connections: one per tie, the connection never
# goes back to the pool inside one
reset_all();
$FakeDbh::down{$ds} = 1;
quiet { $class->new->insert( session() ) };
# A tie that reads then writes: the row read FOR UPDATE stays locked until
# the commit at untie, nothing given back before
{
    @FakeDbh::sql = ();
    my $s     = session();
    my $store = $class->new;
    $store->materialize($s);
    is( idle($node1), 0, 'Transaction open: connection not idle' );
    ok( !$store->{dbh}->{AutoCommit}, 'Transaction open: AutoCommit off' );

    # Changed: an unchanged session is not written back
    $s->{serialized} = '{"uid":"changed"}';
    $store->update($s);
}
is_deeply( [ statements($node1) ], [qw(BEGIN SELECT UPDATE COMMIT)],
    'materialize and update in one transaction, committed at untie' );
ok( grep( { /FOR UPDATE/ } @FakeDbh::sql ), 'Row read FOR UPDATE' );
ok( idle_autocommit($node1), 'Idle connections have AutoCommit on' );

# A commit that fails: rolled back, the connection is closed, not idle
{
    my $store = $class->new;
    $store->update( session() );
    $FakeDbh::failCommit = 1;
    @FakeDbh::sql        = ();
    my $dbh = $store->{dbh};
    undef $store;
    $FakeDbh::failCommit = 0;
    is( $FakeDbh::sql[-1], "ROLLBACK ON $node1", 'Failed commit: rolled back' );
    ok( !$dbh->{Active}, 'Failed commit: connection closed' );
}
ok( idle_autocommit($node1), 'Failed commit: no idle connection in a transaction' );

# _giveBack() never keeps a connection inside a transaction
{
    my $dbh = FakeDbh->new( $node1, AutoCommit => 1, private_ws_pid => $$,
        private_ws_born => time );
    $dbh->begin_work;
    my $idle = idle($node1);
    Web::Session::Store::Postgres::_giveBack(
        {
            dbh          => $dbh,
            pool_key     => "$node1\0u",
            pool_drops   => $Web::Session::Store::Postgres::DROPS{"$node1\0u"}
              // 0,
            pool_maxidle => 10,
            pool_idle    => 120,
            pool_maxlife => 3600,
        }
    );
    is( idle($node1), $idle, 'Open transaction: not given back' );
    ok( !$dbh->{Active}, 'Open transaction: connection closed' );
}

# No Commit: Patroni commits by default, the pool is used
reset_all();
{
    my $store = $class->new;
    delete $base{Commit};
    $store->insert( session() );
    $base{Commit} = 1;
    ok( defined $store->{pool_key}, 'Commit not set: pool used' );
    ok( $FakeDbh::connects[0]->[1]->{AutoCommit}, 'Commit not set: AutoCommit on' );
}

# Without the pool: the previous behaviour
foreach (
    [ 'KeepConnections => 0', KeepConnections => 0 ],
    [ 'Commit => 0',          Commit          => 0 ],
  )
{
    my ( $label, @args ) = @$_;
    reset_all();
    {
        my $store = $class->new;
        $store->insert( session(@args) );
        ok( !defined $store->{pool_key}, "$label: no pool" );
        ok( !$FakeDbh::connects[0]->[1]->{AutoCommit}, "$label: AutoCommit off" );
        is( $FakeDbh::connects[0]->[3], 'cached', "$label: connect_cached()" );
    }
    is( idle($ds), 0, "$label: nothing in the pool" );
}

# KeepConnections => 0, failover: the shared handle path still switches to
# the new primary
reset_all();
$FakeDbh::down{$ds} = 1;
{
    my $store = $class->new;
    quiet { $store->insert( session( KeepConnections => 0 ) ) };
    is( $store->{dbh}->{Name}, $node1, 'KeepConnections => 0: primary found' );
    ok( !$store->{dbh}->{AutoCommit}, 'KeepConnections => 0: AutoCommit off' );
}
ok( grep( { /^COMMIT/ } @FakeDbh::sql ), 'KeepConnections => 0: committed' );

reset_all();
{
    my $store = $class->new;
    $store->insert( session( noreuse => 1 ) );
    ok( !$FakeDbh::connects[0]->[3], 'noreuse: own connection' );
    ok( !$FakeDbh::connects[0]->[1]->{AutoCommit}, 'noreuse: AutoCommit off' );
    ok( $store->{disconnect}, 'noreuse: closed at untie' );
}
is( idle($ds),             0, 'noreuse: nothing in the pool' );
is( $FakeDbh::disconnects, 1, 'noreuse: connection closed' );

reset_all();
{
    my $dbh   = FakeDbh->new( $ds, AutoCommit => 0 );
    my $store = $class->new;
    $store->insert( session( Handle => $dbh ) );
    is( $store->{dbh},             $dbh, 'Handle: used as is' );
    is( scalar @FakeDbh::connects, 0,    'Handle: no connection opened' );
}

done_testing();
