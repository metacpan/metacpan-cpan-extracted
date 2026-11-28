#!/usr/bin/perl

# Connection reuse of DBI stores (default) and "noreuse" option, tested with
# SQLite

use strict;
use warnings;
use Test::More;
use File::Temp   qw(tempdir);
use Scalar::Util qw(refaddr);

plan skip_all => "DBD::SQLite is needed for this test"
  unless eval {
    require DBI;
    require DBD::SQLite;
    1;
  };

my $dir = tempdir( CLEANUP => 1 );
my $dsn = "dbi:SQLite:dbname=$dir/sessions.db";

# Other connection, used to check that stores leave no transaction open: a
# SQLite transaction that has read the table prevents others from writing
my $other = DBI->connect( $dsn, '', '',
    { RaiseError => 1, PrintError => 0, AutoCommit => 1 } );
$other->do( 'CREATE TABLE sessions (id char(32) not null primary key,'
      . ' a_session text, uid text)' );
$other->sqlite_busy_timeout(100);
my $canWrite = sub {
    eval { $other->do('UPDATE sessions SET uid = uid'); 1 };
};
my $stored = sub {
    $other->selectrow_array( 'SELECT count(*) FROM sessions WHERE id = ?',
        undef, $_[0] );
};
my $quiet = sub {
    local $SIG{__WARN__} = sub { };
    return eval { $_[0]->(); 1 };
};

my $class = 'Web::Session::SQLite';
use_ok($class);

my $args       = { DataSource => $dsn, Commit => 1, Index => 'uid' };
my $noreuse    = { %$args, noreuse => 1 };
my $dbhOf      = sub { tied( %{ $_[0] } )->{object_store}->{dbh} };
my $newSession = sub {
    my ( $a, %data ) = @_;
    my %session;
    tie %session, $class, undef, $a;
    $session{$_} = $data{$_} foreach ( keys %data );
    my $id = $session{_session_id};
    untie %session;
    return $id;
};

my ( %session, $dbh );

# 1. With "noreuse": a new connection for each session, closed at untie
tie %session, $class, undef, $noreuse;
$session{uid} = 'dwho';
my $id = $session{_session_id};
$dbh = $dbhOf->( \%session );
untie %session;
ok( !$dbh->{Active}, 'With noreuse, the connection is closed at untie' );
tie %session, $class, $id, $noreuse;
isnt( refaddr( $dbhOf->( \%session ) ),
    refaddr($dbh), 'With noreuse, each session opens a new connection' );
untie %session;

# 2. By default: the same handle for each session
tie %session, $class, undef, $args;
$session{uid} = 'rtyler';
$id           = $session{_session_id};
$dbh          = $dbhOf->( \%session );
is( $dbh->{AutoCommit}, '', 'Same attributes as with noreuse (AutoCommit)' );
{
    local $SIG{__WARN__} = sub { };    # sqlite_unicode is deprecated
    ok( $dbh->{sqlite_unicode}, 'Same flags as with noreuse' );
}
untie %session;
ok( $dbh->{Active}, 'By default, the connection is kept at untie' );
ok( $stored->($id), 'Session committed' );
ok( $canWrite->(),  'No transaction left open' );

tie %session, $class, $id, $args;
is( refaddr( $dbhOf->( \%session ) ), refaddr($dbh), 'Handle reused' );
is( $session{uid},                    'rtyler',      'Session data retrieved' );
$session{uid} = 'rtyler2';
untie %session;
ok( $canWrite->(), 'No transaction left open after an update' );
tie %session, $class, $id, $noreuse;
is( $session{uid}, 'rtyler2', 'Update committed' );
untie %session;

my $res = $class->searchOn( $args, 'uid', 'rtyler2' );
is_deeply( [ keys %$res ], [$id], 'searchOn works by default' );

# 3. Without Commit, the transaction is rolled back at untie (as disconnect
# did), and doesn't stay open
tie %session, $class, $id, { %$args, Commit => 0 };
is( refaddr( $dbhOf->( \%session ) ), refaddr($dbh), 'Handle reused' );
$session{uid} = 'not committed';
untie %session;
ok( $canWrite->(), 'Commit => 0: no transaction left open' );
tie %session, $class, $id, $args;
is( $session{uid}, 'rtyler2', 'Commit => 0: update rolled back' );
untie %session;

# 4. A failed operation doesn't break the next ones
ok( !eval { tie %session, $class, 'unknown', $args; 1 },
    'Unknown session: tie fails' );
ok(
    !$quiet->(
        sub { $newSession->( { %$args, TableName => 'missing' }, uid => 'x' ) }
    ),
    'Failed insert: tie fails'
);
ok( $canWrite->(), 'No transaction left open after failures' );
tie %session, $class, $id, $args;
is( refaddr( $dbhOf->( \%session ) ), refaddr($dbh), 'Handle still reused' );
is( $session{uid}, 'rtyler2', 'Session retrieved after failures' );
untie %session;

# 5. Deletion
my $id2 = $newSession->( $args, uid => 'deleted' );
tie %session, $class, $id2, $args;
tied(%session)->delete;
untie %session;
ok( !$stored->($id2), 'Session deleted' );
ok( !eval { tie %session, $class, $id2, $args; 1 },
    'Deleted session is not found' );

# 6. A given Handle wins
my $mine = DBI->connect( $dsn, '', '', { RaiseError => 1, AutoCommit => 0 } );
tie %session, $class, $id, { %$args, Handle => $mine };
is( refaddr( $dbhOf->( \%session ) ), refaddr($mine), 'Given Handle is used' );
untie %session;
ok( $mine->{Active}, 'Given Handle is not closed' );

# 7. Lost connection: a new one is opened
$dbh->disconnect;
tie %session, $class, $id, $args;
my $new = $dbhOf->( \%session );
ok( ( $new->{Active} and refaddr($new) != refaddr($dbh) ),
    'Lost connection replaced' );
is( $session{uid}, 'rtyler2', 'Session retrieved with the new connection' );
untie %session;
tie %session, $class, $id, $args;
is( refaddr( $dbhOf->( \%session ) ), refaddr($new), 'New handle reused' );
untie %session;

# 8. Each store keeps the attributes of its own connections. The second
# column marks the stores whose materialize() fails here (the session was
# rolled back, or the query isn't SQLite's), which provides a failure. The
# third one gives other arguments: the Postgres and Patroni stores use the
# connection pool by default (see 9.), KeepConnections => 0 gives back
# connect_cached()
my %stores = (
    Postgres  => [ 0, 1, { KeepConnections => 0 } ],
    Patroni   => [ 0, 0, { KeepConnections => 0 } ],
    SQLite    => [ 0, 0 ],
    MySQL     => [ 1, 0 ],
    Cassandra => [ 1, 1 ],
);
my $n = 0;
foreach my $name ( sort keys %stores ) {
    my ( $autoCommit, $failingMaterialize, $extra ) = @{ $stores{$name} };
    my $store = "Web::Session::Store::$name";
    use_ok($store);
    my $session = sub {
        my ( $sid, %a ) = @_;
        return {
            args => { DataSource  => $dsn, Commit => 1, %{ $extra || {} }, %a },
            data => { _session_id => $sid },
            serialized => '{}',
        };
    };
    my ( $s, $sid, $d ) = ( $store->new, "$name-" . $n++ );
    $s->insert( $session->($sid) );
    $d = $s->{dbh};
    is( $d->{AutoCommit} ? 1 : 0, $autoCommit, "$name: AutoCommit" );
    undef $s;
    ok( $d->{Active},    "$name: connection kept" );
    ok( $stored->($sid), "$name: session stored" );
    ok( $canWrite->(),   "$name: no transaction left open" );

    $s = $store->new;
    $s->connection( $session->($sid) );
    is( refaddr( $s->{dbh} ), refaddr($d), "$name: handle reused" );
    undef $s;

    $s = $store->new;
    $s->connection( $session->( $sid, noreuse => 1 ) );
    isnt( refaddr( $s->{dbh} ), refaddr($d), "$name: noreuse: new handle" );
    ok( $s->{disconnect}, "$name: noreuse: connection closed by the store" );
    undef $s;

    # Without Commit, the insertion is rolled back when AutoCommit is off
    ( $s, $sid ) = ( $store->new, "$name-" . $n++ );
    $s->insert( $session->( $sid, Commit => 0 ) );
    undef $s;
    is( $stored->($sid) ? 1 : 0, $autoCommit, "$name: Commit => 0" );
    ok( $canWrite->(), "$name: Commit => 0: no transaction left open" );

    if ($failingMaterialize) {
        $s = $store->new;
        ok( !$quiet->( sub { $s->materialize( $session->($sid) ) } ),
            "$name: materialize() fails with SQLite" );
        undef $s;
        ok( $canWrite->(), "$name: no transaction left open after failure" );
    }
}

# 9. The Postgres store uses its connection pool by default when Commit is
# set: a connection lent to one store at a time, AutoCommit on
{
    my $store   = 'Web::Session::Store::Postgres';
    my $session = sub {
        my ( $sid, %a ) = @_;
        return {
            args       => { DataSource  => $dsn, Commit => 1, %a },
            data       => { _session_id => $sid },
            serialized => '{}',
        };
    };
    my ( $s1, $s2 ) = ( $store->new, $store->new );
    my ( $sid1, $sid2 ) = ( 'pool-' . $n++, 'pool-' . $n++ );
    $s1->insert( $session->($sid1) );
    $s2->insert( $session->($sid2) );
    my ( $d1, $d2 ) = ( $s1->{dbh}, $s2->{dbh} );
    ok( defined $s1->{pool_key}, 'Postgres: pool used by default' );
    ok( $d1->{AutoCommit},       'Postgres pool: AutoCommit on' );
    isnt( refaddr($d1), refaddr($d2),
        'Postgres pool: two stores at once, two connections' );
    ok( !$stored->($sid1), 'Postgres pool: new session not written at tie' );
    $s1->update( $session->($sid1) );
    ok( $stored->($sid1), 'Postgres pool: written by its update, at once' );
    undef $s2;
    undef $s1;
    ok( $stored->($sid2), 'Postgres pool: unmodified, inserted when freed' );
    ok( $d1->{Active}, 'Postgres pool: connection kept' );
    ok( $canWrite->(), 'Postgres pool: no transaction left open' );
    $s1 = $store->new;
    $s1->connection( $session->($sid1) );
    is( refaddr( $s1->{dbh} ), refaddr($d1), 'Postgres pool: handle reused' );
    undef $s1;

    # Without Commit, connect_cached() and a rollback, as with
    # KeepConnections => 0
    $s1 = $store->new;
    my $sid3 = 'pool-' . $n++;
    $s1->insert( $session->( $sid3, Commit => 0 ) );
    ok( !defined $s1->{pool_key},  'Postgres without Commit: no pool' );
    ok( !$s1->{dbh}->{AutoCommit}, 'Postgres without Commit: AutoCommit off' );
    undef $s1;
    ok( !$stored->($sid3), 'Postgres without Commit: rolled back' );
    ok( $canWrite->(), 'Postgres without Commit: no transaction left open' );
}

# 10. The Patroni store uses the same pool, Commit being set by default (no
# Patroni API call here: the connection doesn't fail)
{
    my $store   = 'Web::Session::Store::Patroni';
    my $session = sub {
        my ( $sid, %a ) = @_;
        return {
            args       => { DataSource  => $dsn, %a },
            data       => { _session_id => $sid },
            serialized => '{}',
        };
    };
    # One transaction per tie, as without the pool (the row read by
    # materialize() stays locked until untie). The second store only
    # connects: SQLite allows one writing transaction at a time
    my ( $s1, $s2 ) = ( $store->new, $store->new );
    my $sid1 = 'patroni-pool-' . $n++;
    $s1->insert( $session->($sid1) );
    $s2->connection( $session->( 'patroni-pool-' . $n++ ) );
    my ( $d1, $d2 ) = ( $s1->{dbh}, $s2->{dbh} );
    ok( defined $s1->{pool_key}, 'Patroni: pool used by default' );
    ok( !$d1->{AutoCommit}, 'Patroni pool: transaction open during the tie' );
    isnt( refaddr($d1), refaddr($d2),
        'Patroni pool: two stores at once, two connections' );
    ok( !$stored->($sid1), 'Patroni pool: not committed before untie' );
    undef $s2;
    undef $s1;
    ok( $stored->($sid1),  'Patroni pool: committed at untie' );
    ok( $d1->{Active},     'Patroni pool: connection kept' );
    ok( $d1->{AutoCommit}, 'Patroni pool: given back with AutoCommit on' );
    ok( $canWrite->(),     'Patroni pool: no transaction left open' );
    $s1 = $store->new;
    $s1->connection( $session->($sid1) );
    is( refaddr( $s1->{dbh} ), refaddr($d1), 'Patroni pool: handle reused' );
    undef $s1;
}

done_testing();
