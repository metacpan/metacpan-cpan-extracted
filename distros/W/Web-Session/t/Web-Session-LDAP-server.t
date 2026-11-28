use Test::More;
use strict;

# Tests against a real directory. Example with a local OpenLDAP:
#   LDAP_URL=ldap://127.0.0.1:389 LDAP_BINDDN=cn=admin,dc=example,dc=com \
#   LDAP_BINDPW=secret LDAP_BASE=dc=example,dc=com prove -l t/
# The tests run in a temporary container created under LDAP_BASE.

plan skip_all => 'Set LDAP_URL and LDAP_BASE to run LDAP server tests'
  unless ( $ENV{LDAP_URL} and $ENV{LDAP_BASE} );
plan skip_all => 'Optional modules (Net::LDAP) not installed'
  unless eval { require Net::LDAP; };

my $ldap = Net::LDAP->new( $ENV{LDAP_URL}, onerror => undef )
  or plan skip_all => "Unable to connect to $ENV{LDAP_URL}: $@";
my $msg =
    $ENV{LDAP_BINDDN}
  ? $ldap->bind( $ENV{LDAP_BINDDN}, password => $ENV{LDAP_BINDPW} )
  : $ldap->bind;
plan skip_all => 'Bind failed: ' . $msg->error if $msg->code;

my $package = 'Web::Session::LDAP';
use_ok($package);

my $container = "ou=asb-test-$$,$ENV{LDAP_BASE}";
my $args      = {
    ldapServer       => $ENV{LDAP_URL},
    ldapConfBase     => $container,
    ldapBindDN       => $ENV{LDAP_BINDDN},
    ldapBindPassword => $ENV{LDAP_BINDPW},
    Index            => 'uid',
};

$msg = $ldap->add(
    $container,
    attrs => [
        objectClass => 'organizationalUnit',
        ou          => "asb-test-$$",
    ]
);
BAIL_OUT( "Unable to create $container: " . $msg->error ) if $msg->code;
my $created = 1;

END {
    if ($created) {
        clean();
        $ldap->delete($container);
    }
}

# Remove everything below the container, deepest first
sub clean {
    my $res = $ldap->search(
        base   => $container,
        filter => '(objectClass=*)',
        attrs  => ['1.1'],
    );
    $ldap->delete($_)
      foreach sort { length($b) <=> length($a) }
      grep { $_ ne $container } map { $_->dn } $res->entries;
}

sub ids {
    return [ sort keys %{ $_[0] } ];
}

# Runs $sub with STDERR captured, returns what was printed
sub stderrOf {
    my ($sub) = @_;
    my $buf = '';
    open my $saved, '>&', \*STDERR or die $!;
    close STDERR;
    open STDERR, '>', \$buf or die $!;
    eval { $sub->() };
    close STDERR;
    open STDERR, '>&', $saved or die $!;
    die $@ if $@;
    return $buf;
}

sub newSession {
    my ( $data, $a ) = @_;
    my %h;
    tie %h, $package, undef, ( $a || $args );
    $h{$_} = $data->{$_} foreach keys %$data;
    my $id = $h{_session_id};
    untie %h;
    return $id;
}

# get_key_from_all_sessions() must see sessions without any indexed value
# (#38)
my $idx   = newSession( { uid => 'dwho' } );
my $noIdx = newSession( { foo => 'bar' } );
my $all   = $package->get_key_from_all_sessions($args);
is_deeply(
    [ sort keys %$all ],
    [ sort ( $idx, $noIdx ) ],
    'get_key_from_all_sessions: sessions with and without index'
);
is( $all->{$noIdx}->{foo}, 'bar', 'Session without index: data' );
$all = $package->get_key_from_all_sessions( $args, 'foo' );
is_deeply( $all->{$noIdx}, { foo => 'bar' }, 'Field extraction' );

# Paged searches
{
    my $idx2 = newSession( { uid => 'dwho2' } );
    no warnings 'redefine';
    my $orig     = \&Net::LDAP::search;
    my $requests = 0;
    local *Net::LDAP::search = sub { $requests++; $orig->(@_) };
    local $Web::Session::LDAP::PageSize = 1;
    is( scalar keys %{ $package->get_key_from_all_sessions($args) },
        3, 'get_key_from_all_sessions: all sessions with 1 per page' );
    ok( $requests >= 3, 'get_key_from_all_sessions: paged' );
    $requests = 0;
    is_deeply(
        ids( $package->searchOnExpr( $args, 'uid', 'dwho*' ) ),
        [ sort ( $idx, $idx2 ) ],
        'searchOnExpr with 1 per page'
    );
    ok( $requests >= 2, 'searchOnExpr: paged' );
}

# searchLt() / searchGt()
clean();
$args->{Index} = 'uid _session_kind _oidcRtUpdate';
my %s = (
    short  => newSession( { uid => 'short',  _oidcRtUpdate => 99 } ),
    low    => newSession( { uid => 'low',    _oidcRtUpdate => 998 } ),
    equal  => newSession( { uid => 'equal',  _oidcRtUpdate => 1000 } ),
    high   => newSession( { uid => 'high',   _oidcRtUpdate => 1001 } ),
    long   => newSession( { uid => 'long',   _oidcRtUpdate => 10000 } ),
    dec    => newSession( { uid => 'dec',    _oidcRtUpdate => '999.5' } ),
    nan    => newSession( { uid => 'nan',    _oidcRtUpdate => 'abc' } ),
    spaced => newSession( { uid => 'spaced', _oidcRtUpdate => ' 999 ' } ),
    none   => newSession( { uid => 'none' } ),
    unindx => newSession( { uid => 'unindx', counter => 5 } ),
);
my %name = reverse %s;

sub names {
    [ sort map { $name{$_} } keys %{ $_[0] } ]
}

{
    # Also check that the paged search loops
    local $Web::Session::LDAP::PageSize = 2;
    my $res = $package->searchLt( $args, '_oidcRtUpdate', 1000 );
    is_deeply(
        names($res),
        [qw(dec low short spaced)],
        'searchLt: lower values of any length, not equal/missing/NaN'
    );
    is( $res->{ $s{low} }->{uid}, 'low', 'searchLt: whole session' );
}
my $res = $package->searchLt( $args, '_oidcRtUpdate', 1000, 'uid' );
is_deeply(
    $res->{ $s{short} },
    { uid => 'short' },
    'searchLt: requested fields only'
);
is_deeply( names( $package->searchGt( $args, '_oidcRtUpdate', 1000 ) ),
    [qw(high long)], 'searchGt: greater values, not equal' );
is_deeply( names( $package->searchLt( $args, '_oidcRtUpdate', '999.5' ) ),
    [qw(low short spaced)], 'searchLt: decimal value' );
is_deeply( names( $package->searchLt( $args, '_oidcRtUpdate', ' 100 ' ) ),
    ['short'], 'searchLt: value with spaces' );
is_deeply( names( $package->searchLt( $args, '_oidcRtUpdate', -1 ) ),
    [], 'searchLt: negative value' );
is_deeply( names( $package->searchLt( $args, 'counter', 6 ) ),
    ['unindx'], 'searchLt: non indexed field' );
is_deeply( names( $package->searchGt( $args, 'counter', 5 ) ),
    [], 'searchGt: non indexed field, equal' );

foreach my $bad ( 'abc', '1e3', '', undef, '10; (cn=*)' ) {
    my $r;
    my $err =
      stderrOf(
        sub { $r = $package->searchLt( $args, '_oidcRtUpdate', $bad ) } );
    my $d = defined $bad ? "'$bad'" : 'undef';
    is_deeply( $r, {}, "searchLt: invalid value $d" );
    like( $err, qr/searchLt: value must be a number/, "... warns ($d)" );
}

# Like LLNG purge: refresh tokens not updated since 1 hour
clean();
my $now = time;
my $old = newSession(
    {
        _session_kind => 'OIDCI',
        _type         => 'refresh_token',
        _oidcRtUpdate => $now - 7200,
    }
);
my $recent = newSession(
    {
        _session_kind => 'OIDCI',
        _type         => 'refresh_token',
        _oidcRtUpdate => $now - 60,
    }
);
my $sso = newSession( { _session_kind => 'SSO', _utime => $now - 7200 } );
$res = $package->searchLt( $args, '_oidcRtUpdate', $now - 3600 );
is_deeply( ids($res), [$old], 'Purge-like searchLt: only the old token' );
is( $res->{$old}->{_type}, 'refresh_token', 'Purge-like searchLt: session' );

# LDAP errors: empty result and a warning, no die (LLNG purge doesn't catch)
{
    no warnings 'redefine';
    my $orig = \&Net::LDAP::search;

    # Server size limit
    local *Net::LDAP::search = sub { $orig->( @_, sizelimit => 1 ) };
    my $err = stderrOf(
        sub { $res = $package->searchLt( $args, '_oidcRtUpdate', $now ) } );
    is_deeply( $res, {}, 'searchLt: size limit exceeded, empty result' );
    like( $err, qr/searchLt: LDAP error 4/, '... and a warning' );
}
my $err = stderrOf(
    sub {
        $res =
          $package->searchGt( { %$args, ldapServer => 'ldap://127.0.0.1:1' },
            '_oidcRtUpdate', 1 );
    }
);
is_deeply( $res, {}, 'searchGt: connection error, empty result' );
like( $err, qr/searchGt: unable to connect/, '... and a warning' );

# Bind error (wrong password): same contract as a connection error
SKIP: {
    skip 'Bind DN not set', 2 unless length( $args->{ldapBindDN} // '' );
    $err = stderrOf(
        sub {
            $res =
              $package->searchLt( { %$args, ldapBindPassword => 'wrong' },
                '_oidcRtUpdate', 1 );
        }
    );
    is_deeply( $res, {}, 'searchLt: bind error, empty result' );
    like( $err, qr/searchLt: unable to connect/, '... and a warning' );
}

# Only sessions stored directly under ldapConfBase are seen
clean();
$args->{Index} = 'uid _utime';
my $top    = newSession( { uid => 'top', _utime => 5 } );
my $nested = "ou=nested,$container";
$ldap->add( $nested,
    attrs => [ objectClass => 'organizationalUnit', ou => 'nested' ] );
my $nestedId = newSession( { uid => 'nested', _utime => 5 },
    { %$args, ldapConfBase => $nested } );
is_deeply( ids( $package->get_key_from_all_sessions($args) ),
    [$top], 'get_key_from_all_sessions: nested session ignored' );
is_deeply( ids( $package->searchOn( $args, 'uid', 'nested' ) ),
    [], 'searchOn: nested session ignored' );
is_deeply( ids( $package->searchOnExpr( $args, 'uid', 'n*' ) ),
    [], 'searchOnExpr: nested session ignored' );
is_deeply( ids( $package->searchLt( $args, '_utime', 10 ) ),
    [$top], 'searchLt: nested session ignored' );
is_deeply(
    ids(
        $package->get_key_from_all_sessions(
            { %$args, ldapConfBase => $nested }
        )
    ),
    [$nestedId],
    'Nested session found from its own branch'
);

# deleteIfLowerThan()
$args->{Index} = 'uid _session_kind _utime _lastSeen';

# Creates sessions named by their uid, returns remaining sessions names
sub createSessions {
    clean();
    my %sessions = @_;
    newSession( { uid => $_, %{ $sessions{$_} } } ) foreach keys %sessions;
}

sub remaining {
    my $all = $package->get_key_from_all_sessions( $args, 'uid' );
    return [ sort map { $_->{uid} } values %$all ];
}

my %llng = (
    equal      => { _session_kind => 'SSO',        _utime => 1000 },
    lower      => { _session_kind => 'SSO',        _utime => 999 },
    shorter    => { _session_kind => 'SSO',        _utime => 99 },
    longer     => { _session_kind => 'SSO',        _utime => 10000 },
    decimal    => { _session_kind => 'SSO',        _utime => '999.9' },
    spaced     => { _session_kind => 'SSO',        _utime => ' 999 ' },
    persistent => { _session_kind => 'Persistent', _utime => 5 },
    nokind     => { _utime        => 5 },
    inactive   => { _session_kind => 'SSO', _utime => 1500, _lastSeen => 900 },
    active     => { _session_kind => 'SSO', _utime => 1500, _lastSeen => 1000 },
    onlyLast   => { _session_kind => 'SSO', _lastSeen => 5 },
    noTime     => { _session_kind => 'SSO' },
    nan        => { _session_kind => 'SSO', _utime => 'abc' },
);
createSessions(%llng);
my @r;
{
    local $Web::Session::LDAP::PageSize = 3;
    @r = $package->deleteIfLowerThan(
        $args,
        {
            not => { _session_kind => 'Persistent' },
            or  => { _utime        => 1000, _lastSeen => 1000 }
        }
    );
}
is_deeply( \@r, [ 1, 7 ], 'deleteIfLowerThan (or + not): 7 deleted' );
is_deeply(
    remaining(),
    [qw(active equal longer nan noTime persistent)],
    'deleteIfLowerThan (or + not): remaining sessions'
);

# Nothing left to delete
@r = $package->deleteIfLowerThan( $args,
    { not => { _session_kind => 'Persistent' }, or => { _utime => 1000 } } );
is_deeply( \@r, [ 1, 0 ], 'deleteIfLowerThan: nothing to delete' );

# and
createSessions(
    both    => { _utime => 1, _lastSeen => 1 },
    oneLow  => { _utime => 1, _lastSeen => 100 },
    noLast  => { _utime => 1 },
    noneLow => { _utime => 100, _lastSeen => 100 },
);
ok(
    scalar $package->deleteIfLowerThan(
        $args, { and => { _utime => 100, _lastSeen => 100 } }
    ),
    'deleteIfLowerThan (and): scalar context'
);
is_deeply(
    remaining(),
    [qw(noLast noneLow oneLow)],
    'deleteIfLowerThan (and): remaining sessions'
);

# Unsupported rules: false, nothing deleted
createSessions(%llng);
my $before = remaining();
my $err    = stderrOf(
    sub {
        foreach (
            [ { or => { foo => 10**9 } }, 'non indexed field' ],
            [
                { or => { _utime => 10**9 }, not => { foo => 'a' } },
                'non indexed "not" field'
            ],
            [ { or  => { _utime => 'abc' } },    'invalid threshold' ],
            [ { or  => { _utime => '1e9' } },    'exponent threshold' ],
            [ { or  => { _utime => '(cn=*)' } }, 'filter as threshold' ],
            [ { and => {} }, 'no field' ],
          )
        {
            my @r = $package->deleteIfLowerThan( $args, $_->[0] );
            is_deeply( \@r, [ 0, 0 ],
                "deleteIfLowerThan: $_->[1] returns ( 0, 0 )" );
        }
    }
);
like( $err, qr/threshold must be a number/, 'Invalid threshold is reported' );
is_deeply( remaining(), $before, 'Unsupported rules deleted nothing' );

# Connection error: false
$err = stderrOf(
    sub {
        @r = $package->deleteIfLowerThan(
            { %$args, ldapServer => 'ldap://127.0.0.1:1' },
            { or                 => { _utime => 10**9 } } );
    }
);
is_deeply( \@r, [ 0, 0 ], 'deleteIfLowerThan: connection error returns ( 0, 0 )' );
like( $err, qr/unable to connect/, 'Connection error is reported' );
is_deeply( remaining(), $before, 'Connection error deleted nothing' );

# Bind error (wrong password): false
SKIP: {
    skip 'Bind DN not set', 3 unless length( $args->{ldapBindDN} // '' );
    $err = stderrOf(
        sub {
            @r = $package->deleteIfLowerThan(
                { %$args, ldapBindPassword => 'wrong' },
                { or                       => { _utime => 10**9 } } );
        }
    );
    is_deeply( \@r, [ 0, 0 ], 'deleteIfLowerThan: bind error returns ( 0, 0 )' );
    like( $err, qr/unable to connect/, 'Bind error is reported' );
    is_deeply( remaining(), $before, 'Bind error deleted nothing' );
}

# Search error: false
$err = stderrOf(
    sub {
        @r = $package->deleteIfLowerThan(
            { %$args, ldapConfBase => "ou=missing,$container" },
            { or                   => { _utime => 10**9 } } );
    }
);
is_deeply( \@r, [ 0, 0 ], 'deleteIfLowerThan: search error returns false' );
like( $err, qr/LDAP error 32/, 'Search error is reported' );

# Delete errors
{

    package MockResult;
    sub code  { 50 }
    sub error { 'denied' }
}
my $origDelete = \&Net::LDAP::delete;
createSessions( map { ( $_ => { _utime => 1 } ) } qw(a b c) );
{
    no warnings 'redefine';
    my $n = 0;
    local *Net::LDAP::delete = sub {
        my ( $l, $dn ) = @_;

        # First session removed meanwhile (logout), then an error
        $origDelete->( $ldap, $dn ) if ( $n == 0 );
        return bless {}, 'MockResult' if ( $n++ == 2 );
        return $origDelete->(@_);
    };
    $err = stderrOf(
        sub {
            @r =
              $package->deleteIfLowerThan( $args, { or => { _utime => 10 } } );
        }
    );
}
is_deeply(
    \@r,
    [ 0, 1 ],
    'deleteIfLowerThan: delete error returns false and the deleted count'
);
like( $err, qr/LDAP error 50: denied/, 'Delete error is reported' );
is( scalar @{ remaining() }, 1, 'Session not deleted after the error' );

my $llngRule = {
    not => { _session_kind => 'Persistent' },
    or  => { _utime        => 1000, _lastSeen => 1000 }
};

# Sessions written before _session_kind was indexed: their content is read
createSessions( sso => { _session_kind => 'SSO', _utime => 5 } );
foreach (qw(Persistent persistent SSO)) {
    newSession( { uid => "old$_", _session_kind => $_, _utime => 5 },
        { %$args, Index => 'uid _utime' } );
}
@r = $package->deleteIfLowerThan( $args, $llngRule );
is_deeply( \@r, [ 1, 2 ], 'Stale "not" index: 2 deleted' );
is_deeply(
    remaining(),
    [qw(oldPersistent oldpersistent)],
    'Stale "not" index: Persistent sessions kept'
);

# Sessions in nested branches aren't deleted
createSessions( top => { _utime => 5 } );
$ldap->add( $nested,
    attrs => [ objectClass => 'organizationalUnit', ou => 'nested' ] );
$nestedId = newSession( { uid => 'nested', _utime => 5 },
    { %$args, ldapConfBase => $nested } );
@r = $package->deleteIfLowerThan( $args, $llngRule );
is_deeply( \@r, [ 1, 1 ], 'Nested branch: only 1 deleted' );
ok(
    $package->get_key_from_all_sessions( { %$args, ldapConfBase => $nested } )
      ->{$nestedId},
    'Nested branch: session kept'
);

# Sessions updated between the search and the deletion are kept
createSessions( map { ( $_ => { _utime => 5, _lastSeen => 5 } ) } qw(a b) );
{
    no warnings 'redefine';
    my $n = 0;
    local *Net::LDAP::delete = sub {
        my ( $l, $dn ) = @_;

        # First session refreshed meanwhile
        if ( $n++ == 0 ) {
            my $e = $ldap->search(
                base   => $dn,
                scope  => 'base',
                filter => '(objectClass=*)',
                attrs  => ['ou']
            )->shift_entry;
            $ldap->modify(
                $dn,
                replace => {
                    ou => [
                        map {
                            ( my $v = $_ ) =~ s/^(_utime|_lastSeen)_.*/$1_2000/;
                            $v
                        } $e->get_value('ou')
                    ]
                }
            );
        }
        return $origDelete->(@_);
    };
    @r = $package->deleteIfLowerThan( $args, $llngRule );
}
is_deeply( \@r, [ 1, 1 ], 'Updated meanwhile: not deleted, not counted' );
is( scalar @{ remaining() }, 1, 'Updated meanwhile: session kept' );

done_testing();
