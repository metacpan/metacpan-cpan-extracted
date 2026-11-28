use strict;
use warnings;
no warnings 'once';
use Test::More;
use Scalar::Util qw(refaddr);
use File::Spec;

# Class methods of Web::Session::PgJSON borrow a connection of the pool of
# Web::Session::Store::Postgres for the duration of each call, with the same
# arguments as sessions (Commit not 0, KeepConnections not disabled, no noreuse,
# no Handle). Without database: DBI connections are mocked. The same methods
# run against PostgreSQL in Web-Session-PgJSON.t (with the pool) and
# Web-Session-PgJSON-noPool.t (without) when PG_DSN is set
plan skip_all => 'DBI, Apache::Session and JSON are needed for this test'
  unless eval {
    require DBI;
    require Apache::Session::Store::Postgres;
    require JSON;
    1;
  };

{

    package FakeDbh;
    our ( @connects, @sql, $disconnects, @rows );

    sub new {
        my ( $class, %attr ) = @_;
        return bless {
            Active => 1,
            Driver => { Name => 'Pg' },
            Type   => 'db',
            %attr,
        }, $class;
    }

    sub ping { 1 }

    sub disconnect {
        $_[0]->{Active} = 0;
        $disconnects++;
        return 1;
    }

    sub quote_identifier {
        my ( $self, $name ) = @_;
        $name =~ s/"/""/g;
        return qq{"$name"};
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
    sub commit   { 1 }
    sub rollback { 1 }

    # A statement fails if its connection has "fail" set
    sub _run {
        my ( $h, $dbh, $sql ) = @_;
        push @sql, [ $sql, $dbh ];
        if ( $dbh->{fail} ) {
            my $err = 'cannot execute DELETE in a read-only transaction';
            $h->{HandleError}->( $err, $h, undef ) if ( $h->{HandleError} );
            die "$err\n";
        }
    }

    sub do {
        my ( $self, $sql ) = @_;
        _run( $self, $self, $sql );
        return 2;
    }

    sub selectrow_array {
        my ( $self, $sql ) = @_;
        _run( $self, $self, $sql );
        return 'jsonb';
    }

    package FakeSth;
    sub bind_param { 1 }
    sub finish     { 1 }

    sub execute {
        my ($self) = @_;
        FakeDbh::_run( $self, $self->{Database}, $self->{sql} );
        return 1;
    }

    sub fetchall_hashref {
        return { map { ( $_->[0] => { id => $_->[0], a_session => $_->[1] } ) }
              @FakeDbh::rows };
    }

    # Sessions read by _forEachSession(): one batch
    sub fetchall_arrayref {
        my ($self) = @_;
        return [] if ( $self->{sql} =~ /WHERE id >/ );
        return [ map { [@$_] } @FakeDbh::rows ];
    }
}

my $class = 'Web::Session::PgJSON';
use_ok($class);

no warnings 'redefine';
local *DBI::connect = sub {
    my ( undef, $ds, $user, $pass, $attr ) = @_;
    my $dbh = FakeDbh->new(%$attr);
    push @FakeDbh::connects, [ $ds, $attr, $dbh ];
    return $dbh;
};
local *DBI::connect_cached = sub {
    my ( undef, $ds, $user, $pass, $attr ) = @_;
    my $dbh = FakeDbh->new(%$attr);
    push @FakeDbh::connects, [ $ds, $attr, $dbh, 'cached' ];
    return $dbh;
};
use warnings 'redefine';

my %base = (
    DataSource => 'dbi:Pg:dbname=sessions',
    UserName   => 'u',
    TableName  => 'sessions',
    Commit     => 1,
);
my $key = "$base{DataSource}\0u";

sub args { return { %base, @_ } }

sub reset_pool {
    %Web::Session::Store::Postgres::IDLE = ();
    @FakeDbh::connects                    = ();
    @FakeDbh::sql                         = ();
    $FakeDbh::disconnects                 = 0;
    @FakeDbh::rows                        = (
        [ 'id1', '{"uid":"dwho","_utime":100}' ],
        [ 'id2', '{"uid":"rtyler","_utime":300}' ],
    );
}

sub pool { $Web::Session::Store::Postgres::IDLE{$key} || [] }
sub idle { scalar @{ pool() } }

# Errors of rows are printed on STDERR
sub quiet {
    my ($sub) = @_;
    open my $save, '>&', \*STDERR or die $!;
    open STDERR, '>', File::Spec->devnull or die $!;
    my @r = eval { $sub->() };
    my $err = $@;
    open STDERR, '>&', $save or die $!;
    die $err if $err;
    return wantarray ? @r : $r[0];
}

# Each class method borrows a pooled connection and gives it back
my @methods = (
    [ searchOn     => sub { $class->searchOn( $_[0], 'uid', 'dwho', 'uid' ) } ],
    [
        'searchOn with GinIndex' => sub {
            $class->searchOn( { %{ $_[0] }, GinIndex => 1 }, 'uid', 'dwho' );
        }
    ],
    [ searchOnExpr => sub { $class->searchOnExpr( $_[0], 'uid', 'dw*' ) } ],
    [ searchLt     => sub { $class->searchLt( $_[0], '_utime', 200 ) } ],
    [ searchGt     => sub { $class->searchGt( $_[0], '_utime', 200 ) } ],
    [
        deleteIfLowerThan => sub {
            $class->deleteIfLowerThan( $_[0], { or => { _utime => 200 } } );
        }
    ],
    [
        'get_key_from_all_sessions' =>
          sub { $class->get_key_from_all_sessions( $_[0] ) }
    ],
    [
        'get_key_from_all_sessions with fields' =>
          sub { $class->get_key_from_all_sessions( $_[0], ['uid'] ) }
    ],
    [
        'get_key_from_all_sessions with a callback' => sub {
            $class->get_key_from_all_sessions( $_[0], sub { $_[0]->{uid} } );
        }
    ],
);
foreach (@methods) {
    my ( $label, $call ) = @$_;
    reset_pool();
    ok( $call->( args() ), "$label: result" );
    is( scalar @FakeDbh::connects, 1, "$label: one connection" );
    ok( !$FakeDbh::connects[0]->[3], "$label: not connect_cached()" );
    ok( $FakeDbh::connects[0]->[1]->{AutoCommit}, "$label: AutoCommit on" );
    is( ref( $FakeDbh::connects[0]->[1]->{HandleError} ),
        'CODE', "$label: HandleError" );
    ok( scalar @FakeDbh::sql, "$label: query sent" );
    is( idle(), 1, "$label: connection given back to the pool" );
    $call->( args() );
    is( scalar @FakeDbh::connects, 1, "$label: idle connection reused" );
    is( idle(),                    1, "$label: given back again" );
    is( $FakeDbh::disconnects,     0, "$label: nothing closed" );
}

# Results read on the pooled connection
reset_pool();
is_deeply(
    $class->get_key_from_all_sessions( args(), sub { $_[0]->{uid} } ),
    { id1 => 'dwho', id2 => 'rtyler' },
    'get_key_from_all_sessions with a callback: result'
);
is_deeply(
    [ $class->deleteIfLowerThan( args(), { or => { _utime => 200 } } ) ],
    [ 1, 2 ],
    'deleteIfLowerThan: result'
);

# Sessions and class methods share the pool
reset_pool();
{
    my %s;
    tie %s, $class, undef, args();
    $s{uid} = 'dwho';
    untie %s;
}
is( idle(), 1, 'Session: connection given back' );
$class->searchOn( args(), 'uid', 'dwho' );
is( scalar @FakeDbh::connects, 1, 'Class method reuses the session one' );
is( idle(),                    1, 'And gives it back' );

# A callback that ties a session or calls a class method gets another
# connection: the one of the running call is lent, not idle
reset_pool();
$class->searchOn( args(), 'uid', 'dwho' );
is( idle(), 1, 'One idle connection' );
{
    my ( $outer, @inner, @idleInCallback );
    @FakeDbh::rows = ( $FakeDbh::rows[0] );
    $class->get_key_from_all_sessions(
        args(),
        sub {
            $outer = $FakeDbh::sql[-1]->[1];
            push @idleInCallback, idle();
            $class->searchOn( args(), 'uid', 'dwho' );
            push @inner, $FakeDbh::sql[-1]->[1];
            my %s;
            tie %s, $class, undef, args();
            $s{uid} = 'nested';
            push @inner, tied(%s)->{object_store}->{dbh};
            $class->get_key_from_all_sessions( args(),
                sub { push @inner, $FakeDbh::sql[-1]->[1]; 1 } );
            untie %s;
            return 1;
        }
    );
    is_deeply( \@idleInCallback, [0], 'Callback: running connection lent' );
    is( scalar @inner, 3, 'Callback: nested calls done' );
    isnt( refaddr( $inner[$_] ), refaddr($outer),
        "Callback: nested use $_ gets another connection" )
      foreach ( 0 .. 2 );
    isnt( refaddr( $inner[1] ), refaddr( $inner[2] ),
        'Callback: session and nested class method, two connections' );
    is( scalar @FakeDbh::connects, 3, 'Callback: three connections opened' );
    is( idle(),                    3, 'Callback: all given back' );
    is( $FakeDbh::disconnects,     0, 'Callback: none closed' );
}

# A callback that dies: its row is skipped (printed on STDERR), the
# connection is given back
reset_pool();
{
    my $res = quiet(
        sub {
            $class->get_key_from_all_sessions( args(),
                sub { die "callback error\n" if ( $_[1] eq 'id1' ); 1 } );
        }
    );
    is_deeply( $res, { id2 => 1 }, 'Callback dies: row skipped' );
    is( idle(),                1, 'Callback dies: connection given back' );
    is( $FakeDbh::disconnects, 0, 'Callback dies: connection kept' );
}

# A nested call that dies in a callback gives back its connection too
reset_pool();
{
    quiet(
        sub {
            $class->get_key_from_all_sessions(
                args(),
                sub {
                    $class->get_key_from_all_sessions( args(),
                        sub { die "inner error\n" } );
                    die "outer error\n";
                }
            );
        }
    );
    is( scalar @FakeDbh::connects, 2, 'Nested die: two connections' );
    is( idle(),                    2, 'Nested die: both given back' );
}

# A query that fails: the method dies (or returns an error), its connection
# is flagged by HandleError and closed, never lent again
foreach (
    [
        searchOn => sub {
            ok( !eval { $class->searchOn( args(), 'uid', 'dwho' ); 1 },
                'searchOn: dies' );
        }
    ],
    [
        get_key_from_all_sessions => sub {
            ok(
                !eval {
                    $class->get_key_from_all_sessions( args(), sub { 1 } );
                    1;
                },
                'get_key_from_all_sessions: dies'
            );
        }
    ],
    [
        deleteIfLowerThan => sub {
            is(
                quiet(
                    sub {
                        $class->deleteIfLowerThan( args(),
                            { or => { _utime => 200 } } );
                    }
                ),
                0,
                'deleteIfLowerThan: returns 0'
            );
        }
    ],
  )
{
    my ( $label, $call ) = @$_;
    reset_pool();
    $class->searchOn( args(), 'uid', 'dwho' );
    my $dbh = pool()->[0]->[0];
    $dbh->{fail} = 1;
    $call->();
    ok( $dbh->{private_ws_error}, "$label error: connection flagged" );
    is( idle(),                "0", "$label error: connection not kept" );
    is( $FakeDbh::disconnects, 1,   "$label error: connection closed" );
    $class->searchOn( args(), 'uid', 'dwho' );
    is( scalar @FakeDbh::connects, 2, "$label error: new connection next" );
}

# The error of a failed query is kept: closing its connection, while the
# error unwinds the call, doesn't clear $@
reset_pool();
{
    $class->searchOn( args(), 'uid', 'dwho' );
    pool()->[0]->[0]->{fail} = 1;
    eval { $class->searchOn( args(), 'uid', 'dwho' ) };
    like( $@, qr/read-only/, 'Query error kept in $@' );
    is( $FakeDbh::disconnects, 1, 'Its connection closed' );
}

# Without the pool (KeepConnections => 0, without Commit, with noreuse or a
# Handle), class methods use the connect_cached() handle as before
foreach (
    [ 'KeepConnections => 0', KeepConnections => 0 ],
    [ 'Without Commit',       Commit          => 0 ],
    [ 'noreuse',              noreuse         => 1 ],
    [ 'Handle',               Handle          => FakeDbh->new ],
  )
{
    my ( $label, @args ) = @$_;
    reset_pool();
    $class->searchOn( args(@args), 'uid', 'dwho' );
    $class->get_key_from_all_sessions( args(@args), sub { 1 } );
    ok( scalar @FakeDbh::connects, "$label: connected" );
    is( scalar( grep { !$_->[3] } @FakeDbh::connects ),
        0, "$label: only connect_cached()" );
    is( idle(), 0, "$label: nothing in the pool" );
}

# KeepConnections => '' keeps the default (the pool)
reset_pool();
$class->searchOn( args( KeepConnections => '' ), 'uid', 'dwho' );
is( idle(), 1, "KeepConnections => '': pool used" );

# _classDbh() still returns the connect_cached() handle
reset_pool();
$class->_classDbh( args() );
is( $FakeDbh::connects[0]->[3], 'cached', '_classDbh(): connect_cached()' );
is( idle(), 0, '_classDbh(): nothing in the pool' );

# Patroni sessions don't use the pool: its class methods keep connect_cached()
SKIP: {
    skip 'Web::Session::Patroni can\'t be loaded', 2
      unless ( eval { require Web::Session::Patroni } );
    reset_pool();
    Web::Session::Patroni->searchOn( args(), 'uid', 'dwho' );
    is( $FakeDbh::connects[0]->[3], 'cached', 'Patroni: connect_cached()' );
    is( idle(), 0, 'Patroni: nothing in the pool' );
}

# Web::Session::Postgres is an alias: it uses the pool
SKIP: {
    skip 'Web::Session::Postgres can\'t be loaded', 1
      unless ( eval { require Web::Session::Postgres } );
    reset_pool();
    Web::Session::Postgres->searchOn( args(), 'uid', 'dwho' );
    is( idle(), 1, 'Postgres alias: pool used' );
}

done_testing();
