use strict;
use warnings;
no warnings 'once';
use Test::More;
use Scalar::Util ();

# Connection pool of Web::Session::Store::Postgres (used by default with
# Commit, disabled by KeepConnections => 0), without database: DBI
# connections are mocked
plan skip_all => 'DBI and Apache::Session are needed for this test'
  unless eval { require DBI; require Apache::Session::Store::Postgres; 1 };

{

    package FakeDbh;
    our ( @connects, @sql, @bound, $disconnects, $pings, $noRow );

    sub new {
        my ( $class, %attr ) = @_;
        return bless {
            Active => 1,
            Driver => { Name => 'Pg' },
            Type   => 'db',
            alive  => 1,
            %attr,
        }, $class;
    }

    sub ping {
        $pings++;
        return $_[0]->{alive};
    }

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

    package FakeSth;

    sub bind_param {
        my ( $self, $i, $v ) = @_;
        $self->{bind}->[ $i - 1 ] = $v;
        return 1;
    }

    # A statement fails if its connection has "fail" set
    sub execute {
        my ( $self, @values ) = @_;
        push @FakeDbh::sql,   $self->{sql};
        push @FakeDbh::bound, [ @{ $self->{bind} || [] }, @values ];
        if ( $self->{Database}->{fail} ) {
            my $err = 'cannot execute UPDATE in a read-only transaction';
            $self->{HandleError}->( $err, $self, undef )
              if ( $self->{HandleError} );
            die "$err\n";
        }
        return 1;
    }
    sub fetchrow_arrayref { $FakeDbh::noRow ? undef : ['{}'] }
    sub finish            { 1 }
}

my $class = 'Web::Session::Store::Postgres';
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

# No KeepConnections: the pool is the default
my %base = (
    DataSource => 'dbi:Pg:dbname=sessions',
    UserName   => 'u',
    Commit     => 1,
);
my $key = "$base{DataSource}\0u";
my $n   = 0;

sub session {
    my %args = ( %base, @_ );
    return {
        args       => \%args,
        data       => { _session_id => 'id' . ++$n, uid => 'dwho' },
        serialized => '{}',
    };
}

sub reset_pool {
    %Web::Session::Store::Postgres::IDLE = ();
    @FakeDbh::connects                    = ();
    @FakeDbh::sql                         = ();
    @FakeDbh::bound                       = ();
    $FakeDbh::disconnects                 = 0;
    $FakeDbh::pings                       = 0;
}

sub pool { $Web::Session::Store::Postgres::IDLE{$key} || [] }
sub idle { scalar @{ pool() } }

# The pool is used by default with Commit, and with KeepConnections => 1
foreach (
    [ 'Default with Commit', () ],
    [ 'KeepConnections => 1', KeepConnections => 1 ],
    [ "KeepConnections => ''", KeepConnections => '' ],
  )
{
    my ( $label, @args ) = @$_;
    reset_pool();
    {
        my $store = $class->new;
        $store->insert( session(@args) );
        is( scalar @FakeDbh::connects, 1, "$label: one connection" );
        ok( !$FakeDbh::connects[0]->[3], "$label: not connect_cached()" );
        is( $store->{pool_key}, $key, "$label: pooled connection" );
        ok( $FakeDbh::connects[0]->[1]->{AutoCommit}, "$label: AutoCommit on" );
    }
    is( idle(), 1, "$label: connection given back to the pool" );
}

# Connection attributes
reset_pool();
{
    my $store = $class->new;
    $store->connection( session() );
    my $attr = $FakeDbh::connects[0]->[1];
    ok( $attr->{AutoCommit},          'Pooled connection: AutoCommit on' );
    ok( $attr->{AutoInactiveDestroy}, 'Pooled connection: AutoInactiveDestroy' );
    ok( $attr->{RaiseError},          'Pooled connection: RaiseError' );
    is( ref( $attr->{HandleError} ), 'CODE', 'Pooled connection: HandleError' );
}
is( idle(),                1, 'Connection given back to the pool' );
is( $FakeDbh::disconnects, 0, 'Connection not closed' );

# Reused by the next store
{
    my $store = $class->new;
    $store->connection( session() );
    is( scalar @FakeDbh::connects, 1, 'Idle connection reused' );
    is( idle(),                    0, 'Lent: no longer idle' );
}

# A new session is written once: its INSERT waits for the update that
# follows, which inserts it with its data
reset_pool();
{
    my $store = $class->new;
    my $s     = session( Index => 'uid' );
    $store->insert($s);
    is( scalar @FakeDbh::connects, 1, 'insert(): connection taken at tie' );
    is( scalar @FakeDbh::sql,      0, 'insert(): nothing written yet' );
    $store->update($s);
    is( scalar @FakeDbh::sql, 1, 'update() after insert(): one statement' );
    like( $FakeDbh::sql[0], qr/^INSERT INTO .*"uid"/, 'It is the INSERT' );
    $store->update($s);
    is( scalar @FakeDbh::sql, 1, 'Saved again unchanged: nothing written' );
    $s->{serialized} = '{"uid":"changed"}';
    $store->update($s);
    like( $FakeDbh::sql[1], qr/^UPDATE/, 'The next change updates' );
}
is( scalar @FakeDbh::sql, 2, 'Nothing written at untie' );

# _session_id changed between tie and untie (Lemonldap::NG's hashed session
# store): inserted under the id it had at tie
reset_pool();
{
    my $store = $class->new;
    my $s     = session();
    my $id    = $s->{data}->{_session_id};
    $store->insert($s);
    $s->{data}->{_session_id} = 'cookie';
    $store->update($s);
    is( $FakeDbh::bound[0]->[0], $id, 'Changed id: inserted under the tie id' );
    ok( !grep( { defined and $_ eq 'cookie' } map { @$_ } @FakeDbh::bound ),
        'Changed id: nothing written under the other id' );
    is( $s->{data}->{_session_id}, 'cookie', 'Changed id: session unchanged' );
}

# A new session untied without an update is inserted by DESTROY
reset_pool();
{
    my $store = $class->new;
    $store->insert( session() );
}
is( scalar @FakeDbh::sql, 1, 'Unmodified new session: inserted at untie' );
like( $FakeDbh::sql[0], qr/^INSERT INTO/, 'It is an INSERT' );
is( idle(), 1, 'Connection given back after the INSERT' );

# A new session still tied when the program ends: inserted by the END block
# (_flushPending()), before the global destruction
reset_pool();
{
    my $store = $class->new;
    $store->insert( session() );
    Web::Session::Store::Postgres::_flushPending();
    is( scalar @FakeDbh::sql, 1, 'END: pending INSERT written' );
    like( $FakeDbh::sql[0], qr/^INSERT INTO/, 'END: it is the INSERT' );
    Web::Session::Store::Postgres::_flushPending();
    is( scalar @FakeDbh::sql, 1, 'END run twice: inserted once' );
}
is( scalar @FakeDbh::sql, 1, 'END: not inserted again by DESTROY' );
is( idle(),               1, 'END: connection given back by DESTROY' );

# Not inserted by END: written by update(), removed, freed, or lent by a
# parent process
reset_pool();
{
    my $s       = session();
    my $updated = $class->new;
    $updated->insert($s);
    $updated->update($s);
    my $r       = session();
    my $removed = $class->new;
    $removed->insert($r);
    $removed->remove($r);
    my $forked = $class->new;
    $forked->insert( session() );
    $forked->{dbh}->{private_ws_pid} = -1;
    {
        my $freed = $class->new;
        $freed->insert( session() );
    }
    @FakeDbh::sql = ();
    Web::Session::Store::Postgres::_flushPending();
    is( scalar @FakeDbh::sql, 0, 'END: nothing else inserted' );
}
is( scalar @FakeDbh::sql, 0, 'END: forked store not inserted by DESTROY' );

# Unmodified new session with indexed fields, inserted by DESTROY: the
# pending INSERT holds copies of the id and of the indexed values, not the
# session
reset_pool();
{
    my $store = $class->new;
    my $s     = session( Index => 'uid sn' );
    $s->{data}->{sn} = 'Doe';
    my $id = $s->{data}->{_session_id};
    $store->insert($s);
    Scalar::Util::weaken( my $weak = $s );
    undef $s;
    ok( !$weak, 'Pending INSERT: the session is not kept' );
    undef $store;
    like( $FakeDbh::sql[0], qr/^INSERT INTO .*"uid".*"sn"/,
        'Unmodified new session with Index: INSERT of the indexed fields' );
    is_deeply( $FakeDbh::bound[0], [ $id, '{}', 'dwho', 'Doe' ],
        'Unmodified new session with Index: copied values inserted' );
}

# An id given by the caller (setId) is checked at tie: a used one makes the
# tie die, as the INSERT at tie without the pool. A generated id isn't
reset_pool();
{
    my $store = $class->new;
    my $s     = session( setId => 'given' );
    ok( !eval { $store->insert($s); 1 }, 'setId: used id, insert() dies' );
    like( $@, qr/session id\d+ already exists/, 'setId: the error names it' );
    is( scalar @FakeDbh::sql, 1, 'setId: one statement' );
    like( $FakeDbh::sql[0], qr/^SELECT 1 FROM "sessions" WHERE id = \?$/,
        'setId: it is the check' );
    is_deeply( $FakeDbh::bound[0], [ $s->{data}->{_session_id} ],
        'setId: the id is bound' );
}
is( scalar @FakeDbh::sql, 1, 'setId: used id, nothing inserted at untie' );
is( idle(),               1, 'setId: used id, connection given back' );
reset_pool();
{
    local $FakeDbh::noRow = 1;
    my $store = $class->new;
    my $s     = session( setId => 'given' );
    ok( eval { $store->insert($s); 1 }, 'setId: free id, insert() succeeds' );
    is( scalar @FakeDbh::sql, 1, 'setId: free id, checked, not inserted yet' );
}
like( $FakeDbh::sql[1], qr/^INSERT INTO/, 'setId: free id, inserted at untie' );

# Created and removed in the same tie: never written
reset_pool();
{
    my $store = $class->new;
    my $s     = session();
    $store->insert($s);
    $store->remove($s);
}
is( scalar @FakeDbh::sql, 0, 'Created then removed: nothing written' );

# A failed INSERT at untie is a warning, and its connection is closed
reset_pool();
{
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, @_ };
    {
        my $store = $class->new;
        $store->insert( session() );
        $store->{dbh}->{fail} = 1;
    }
    is( scalar @warnings, 1, 'Failed INSERT at untie: a warning' );
    like( $warnings[0], qr/unable to store new session id\d+/,
        'It names the session' );
}
is( idle(),                0, 'Failed INSERT: connection not kept' );
is( $FakeDbh::disconnects, 1, 'Failed INSERT: connection closed' );

# The pending INSERT keeps neither the session nor its arguments: with
# Lemonldap::NG's cache wrapper, the arguments hold the store
reset_pool();
{
    my $destroyed = 0;
    no warnings 'redefine';
    local *Web::Session::Store::Postgres::DESTROY = do {
        my $orig = \&Web::Session::Store::Postgres::DESTROY;
        sub { $destroyed++; $orig->(@_) };
    };
    use warnings 'redefine';
    {
        my $store = $class->new;
        my $s     = session();
        $s->{args}->{object_store} = $store;
        $store->insert($s);
    }
    is( $destroyed, 1, 'Pending INSERT: no cycle through the arguments' );
    is( scalar @FakeDbh::sql, 1, 'The session was inserted' );
}

# A failed deferred INSERT is not forgotten: a new save() inserts again
# instead of updating (or deleting) a row that may be another session's
reset_pool();
{
    my $store = $class->new;
    my $s     = session();
    $store->insert($s);
    $store->{dbh}->{fail} = 1;
    ok( !eval { $store->update($s); 1 }, 'Failed deferred INSERT dies' );
    $store->{dbh}->{fail} = 0;
    $store->update($s);
    like( $FakeDbh::sql[1], qr/^INSERT INTO/, 'Retried save(): INSERT again' );
    $s->{serialized} = '{"uid":"changed"}';
    $store->update($s);
    like( $FakeDbh::sql[2], qr/^UPDATE/, 'Once inserted: UPDATE' );
    $store->remove($s);
    like( $FakeDbh::sql[3], qr/^\s*DELETE/, 'remove() after update(): DELETE' );
}
is( scalar @FakeDbh::sql, 4, 'Nothing more written at untie' );
reset_pool();
{
    my $store = $class->new;
    my $s     = session();
    $store->insert($s);
    $store->{dbh}->{fail} = 1;
    ok( !eval { $store->update($s); 1 }, 'Failed deferred INSERT' );
    $store->{dbh}->{fail} = 0;
    $store->remove($s);
    is( scalar @FakeDbh::sql, 1, 'Then remove(): nothing deleted' );
}
is( scalar @FakeDbh::sql, 1, 'Removed: not inserted at untie' );

# A failed INSERT at untie keeps the caller's $@
reset_pool();
{
    local $SIG{__WARN__} = sub { };
    $@ = 'previous error';
    {
        my $store = $class->new;
        $store->insert( session() );
        $store->{dbh}->{fail} = 1;
    }
    is( $@, 'previous error', "Failed INSERT at untie: \$@ kept" );
}

# Lent with a pending INSERT when the process forked: the child writes
# nothing (the parent does)
reset_pool();
{
    my $store = $class->new;
    $store->insert( session() );
    $store->{dbh}->{private_ws_pid} = -1;
}
is( scalar @FakeDbh::sql,      0, 'Fork: pending INSERT not written by child' );
is( $FakeDbh::disconnects,     0, 'Fork: connection not closed' );
is( idle(),                    0, 'Fork: connection not given back' );

# Through Apache::Session: tie, untie
SKIP: {
    skip 'JSON is needed', 6 unless eval { require Web::Session::PgJSON; 1 };
    my $pg = 'Web::Session::PgJSON';
    my %h;
    reset_pool();
    tie %h, $pg, undef, {%base};
    $h{uid} = 'dwho';
    untie %h;
    is( scalar @FakeDbh::sql, 1, 'tie: new session modified, one statement' );
    like( $FakeDbh::sql[0], qr/^INSERT INTO/, 'It is the INSERT' );
    is( idle(), 1, 'Connection given back at untie' );

    reset_pool();
    tie %h, $pg, undef, {%base};
    untie %h;
    is_deeply( [ map { /^\s*(\w+)/ } @FakeDbh::sql ],
        ['INSERT'], 'tie: new session unmodified, inserted at untie' );

    reset_pool();
    tie %h, $pg, undef, {%base};
    tied(%h)->delete;
    untie %h;
    is( scalar @FakeDbh::sql, 0, 'tie: new session deleted, nothing written' );

    reset_pool();
    tie %h, $pg, 'a' x 64, {%base};
    $h{uid} = 'dwho';
    untie %h;
    is_deeply( [ map { /^\s*(\w+)/ } @FakeDbh::sql ],
        [ 'SELECT', 'UPDATE' ], 'tie: existing session, read then updated' );
}

# Without the pool, insert() writes at once
reset_pool();
{
    my $store = $class->new;
    $store->insert( session( KeepConnections => 0 ) );
    like( $FakeDbh::sql[0], qr/^INSERT INTO/, 'Without pool: INSERT at once' );
}

# Two stores at once never share a connection
reset_pool();
{
    my ( $s1, $s2 ) = ( $class->new, $class->new );
    $s1->connection( session() );
    $s2->connection( session() );
    isnt( $s1->{dbh}, $s2->{dbh}, 'Two stores tied at once: two connections' );
}
is( idle(), 2, 'Both given back' );

# MaxIdle
reset_pool();
{
    my @stores = map { $class->new } 1 .. 3;
    $_->connection( session( MaxIdle => 1 ) ) foreach (@stores);
}
is( idle(),                1, 'MaxIdle: one connection kept' );
is( $FakeDbh::disconnects, 2, 'MaxIdle: the others closed' );

# A connection whose statement failed is closed: HandleError, inherited by
# the statement handle, flags it
reset_pool();
{
    my $store = $class->new;
    my $s     = session();
    $store->connection($s);
    $store->{dbh}->{fail} = 1;
    ok( !eval { $store->update($s); 1 }, 'Failed statement dies' );
    ok( $store->{dbh}->{private_ws_error}, 'Its connection is flagged' );
}
is( idle(),                0, 'Error: connection not kept' );
is( $FakeDbh::disconnects, 1, 'Error: connection closed' );

# The error flag is reset when a connection is lent
reset_pool();
{
    my $store = $class->new;
    $store->connection( session() );
    $store->{dbh}->{private_ws_error} = 1;
    push @{ pool() }, [ $store->{dbh}, time ];
    delete $store->{pool_key};
    delete $store->{dbh};
}
{
    my $store = $class->new;
    $store->connection( session() );
    ok( !$store->{dbh}->{private_ws_error}, 'Error flag reset when lent' );
}

# A connection given back lately is lent without ping if its socket has
# nothing to read, pinged otherwise
reset_pool();
pipe( my $r, my $w ) or die $!;
{
    my $store = $class->new;
    $store->connection( session() );
    $store->{dbh}->{pg_socket} = fileno($r);
}
{
    my $store = $class->new;
    $store->connection( session() );
    is( $FakeDbh::pings, 0, 'Recent connection, empty socket: no ping' );
}
syswrite( $w, 'x' );
{
    my $store = $class->new;
    $store->connection( session() );
    is( $FakeDbh::pings, 1, 'Readable socket: pinged' );
}
pool()->[0]->[1] -= 60;
sysread( $r, my $buf, 1 );
{
    my $store = $class->new;
    $store->connection( session() );
    is( $FakeDbh::pings, 2, 'Connection idle for a while: pinged' );
}

# Dead connection replaced
reset_pool();
{
    my $store = $class->new;
    $store->connection( session() );
}
pool()->[0]->[0]->{alive} = 0;
pool()->[0]->[1] -= 60;
{
    my $store = $class->new;
    $store->connection( session() );
    is( scalar @FakeDbh::connects, 2, 'Dead connection replaced' );
    is( $FakeDbh::disconnects,     1, 'Dead connection closed' );
}

# IdleTimeout: closed without ping
reset_pool();
{
    my $store = $class->new;
    $store->connection( session() );
}
pool()->[0]->[1] -= 200;
{
    my $store = $class->new;
    $store->connection( session( IdleTimeout => 100 ) );
    is( scalar @FakeDbh::connects, 2, 'IdleTimeout: new connection' );
    is( $FakeDbh::pings,           0, 'IdleTimeout: old one not pinged' );
    is( $FakeDbh::disconnects,     1, 'IdleTimeout: old one closed' );
}

# Expired idle connections are closed when a connection is given back, even
# if they were never reached
reset_pool();
{
    my @stores = map { $class->new } 1 .. 2;
    $_->connection( session() ) foreach (@stores);
}
is( idle(), 2, 'Two idle connections' );
pool()->[0]->[1] -= 200;
{
    my $store = $class->new;
    $store->connection( session( IdleTimeout => 100 ) );
}
is( idle(),                1, 'Expired idle connection reaped at give back' );
is( $FakeDbh::disconnects, 1, 'Expired idle connection closed' );

# MaxLifetime
reset_pool();
{
    my $store = $class->new;
    $store->connection( session( MaxLifetime => 100 ) );
    $store->{dbh}->{private_ws_born} -= 200;
}
is( idle(),                0, 'MaxLifetime: old connection not kept' );
is( $FakeDbh::disconnects, 1, 'MaxLifetime: old connection closed' );

# Inherited from a parent process (idle when it forked): neither used nor
# closed
reset_pool();
{
    my $store = $class->new;
    $store->connection( session() );
}
pool()->[0]->[0]->{private_ws_pid} = -1;
{
    my $store = $class->new;
    $store->connection( session() );
    is( scalar @FakeDbh::connects, 2, 'Fork: parent connection not used' );
    is( $FakeDbh::disconnects,     0, 'Fork: parent connection not closed' );
}

# Lent when the process forked: neither given back nor closed by the child
reset_pool();
{
    my $store = $class->new;
    $store->connection( session() );
    $store->{dbh}->{private_ws_pid} = -1;
}
is( idle(),                0, 'Fork: lent connection not given back' );
is( $FakeDbh::disconnects, 0, 'Fork: lent connection not closed' );

# With KeepConnections => 0 (the previous behaviour), or without Commit, or
# with noreuse or a Handle: no pool
foreach (
    [ 'KeepConnections => 0', KeepConnections => 0 ],
    [ 'Without Commit',       Commit          => 0 ],
  )
{
    my ( $label, @args ) = @$_;
    reset_pool();
    {
        my $store = $class->new;
        $store->insert( session(@args) );
        ok( !$FakeDbh::connects[0]->[1]->{AutoCommit},
            "$label: AutoCommit off" );
        is( $FakeDbh::connects[0]->[3],
            'cached', "$label: connection reuse of the other stores" );
    }
    is( idle(), 0, "$label: nothing in the pool" );
}
reset_pool();
{
    my $store = $class->new;
    $store->insert( session( noreuse => 1 ) );
    ok( !$FakeDbh::connects[0]->[3], 'noreuse: own connection' );
}
is( idle(), 0, 'noreuse: nothing in the pool' );
reset_pool();
{
    my $dbh   = FakeDbh->new( AutoCommit => 0 );
    my $store = $class->new;
    $store->insert( session( Handle => $dbh ) );
    is( $store->{dbh},             $dbh, 'Handle: used as is' );
    is( scalar @FakeDbh::connects, 0,    'Handle: no connection opened' );
}
is( idle(), 0, 'Handle: nothing in the pool' );

# Commit is on by default without a Handle: a missing, undef or empty Commit
# commits the writes, so the pool is used
foreach (
    [ 'Commit missing', sub { delete $_[0]->{Commit} } ],
    [ 'Commit undef',   sub { $_[0]->{Commit} = undef } ],
    [ "Commit ''",      sub { $_[0]->{Commit} = '' } ],
  )
{
    my ( $label, $edit ) = @$_;
    reset_pool();
    {
        my $s = session();
        $edit->( $s->{args} );
        my $store = $class->new;
        $store->insert($s);
        is( $store->{pool_key}, $key, "$label: pooled connection" );
        ok( $store->{commit}, "$label: committed" );
    }
    is( idle(), 1, "$label: connection given back" );
}

# Also outside of the pool
foreach (
    [ 'noreuse without Commit',              noreuse         => 1 ],
    [ 'KeepConnections => 0 without Commit', KeepConnections => 0 ],
  )
{
    my ( $label, @args ) = @$_;
    reset_pool();
    my $s = session(@args);
    delete $s->{args}->{Commit};
    my $store = $class->new;
    $store->insert($s);
    ok( !defined $store->{pool_key}, "$label: no pool" );
    ok( $store->{commit},            "$label: committed" );
}

# With a Handle, the caller owns the transaction: Commit is used as given
reset_pool();
{
    my $s = session( Handle => FakeDbh->new( AutoCommit => 0 ) );
    delete $s->{args}->{Commit};
    my $store = $class->new;
    $store->insert($s);
    ok( !$store->{commit}, 'Handle without Commit: not committed' );
}
reset_pool();
{
    my $store = $class->new;
    $store->insert( session( Handle => FakeDbh->new( AutoCommit => 0 ) ) );
    ok( $store->{commit}, 'Handle with Commit: committed' );
}

done_testing();
