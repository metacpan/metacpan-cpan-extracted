use Test::More;

plan skip_all => "Optional modules (Net::LDAP) not installed"
  unless eval {
      require Net::LDAP;
  };

plan tests => 130;

$package = 'Web::Session::Store::LDAP';

use_ok($package);
ok( !$INC{'IO/Socket/Timeout.pm'}, 'IO::Socket::Timeout not loaded' );

# new
my $args  = { ldapServer => 'ldap://localhost' };
my $store = $package->new($args);
isa_ok( $store, $package );
is( $store->{args}, $args, 'new keeps args' );

# new called by Apache::Session with a blessed session object
my $obj = $package->new( bless { args => $args }, 'Some::Session' );
isa_ok( $obj, $package );
ok( !exists $obj->{args}, 'new ignores blessed object' );

# _parseServers
sub parse {
    return $package->new( { ldapServer => shift, @_ } )->_parseServers;
}

my @s = parse('ldap://localhost');
is( $s[0]->{server},   'ldap://localhost', 'plain ldap: server' );
is( $s[0]->{startTls}, 0,                  'plain ldap: no StartTLS' );
is_deeply( $s[0]->{tlsParams}, { verify => 'require' }, 'default verify' );

@s = parse('ldaps://ldap.example.com?verify=none');
is( $s[0]->{server}, 'ldaps://ldap.example.com', 'ldaps without slash' );
is( $s[0]->{tlsParams}->{verify}, 'none',        'verify=none' );

@s = parse('ldaps://host:636?cafile=/etc/ca.pem');
is( $s[0]->{server},              'ldaps://host:636', 'ldaps with port' );
is( $s[0]->{tlsParams}->{cafile}, '/etc/ca.pem',      'cafile' );

@s = parse('ldaps://host/?cafile=/a&verify=optional');
is( $s[0]->{server}, 'ldaps://host', 'ldaps with slash' );
is_deeply(
    $s[0]->{tlsParams},
    { cafile => '/a', verify => 'optional' },
    'several params'
);

@s = parse('ldap+tls://a/?cafile=/ca.pem ldaps://b');
is( scalar @s,                    2,           'two servers' );
is( $s[0]->{server},              'a',         'ldap+tls: host' );
is( $s[0]->{startTls},            1,           'ldap+tls: StartTLS' );
is( $s[0]->{tlsParams}->{cafile}, '/ca.pem',   'ldap+tls: cafile' );
is( $s[1]->{server},              'ldaps://b', 'second server' );
is( $s[1]->{startTls},            0,           'second: no StartTLS' );
ok( !exists $s[1]->{tlsParams}->{cafile}, 'second: no cafile' );

@s = parse( 'ldaps://b', ldapCAFile => '/global.pem' );
is( $s[0]->{tlsParams}->{cafile}, '/global.pem', 'global cafile' );

@s = parse('ldaps://host/?onerror=die&keepalive=0&verify=none');
is_deeply( $s[0]->{tlsParams}, { verify => 'none' }, 'non-TLS keys filtered' );

@s = parse(
    'ldaps://h1/?verify=none&cafile=/url.pem ldaps://h2',
    ldapVerify     => 'optional',
    ldapCAFile     => '/g.pem',
    ldapClientCert => '/cert.pem',
);
is_deeply(
    $s[0]->{tlsParams},
    { verify => 'none', cafile => '/url.pem', clientcert => '/cert.pem' },
    'URL params override globals'
);
is_deeply(
    $s[1]->{tlsParams},
    { verify => 'optional', cafile => '/g.pem', clientcert => '/cert.pem' },
    'globals applied'
);

# _bind
{

    package MockSocket;
    sub new { bless { ssl => $_[1] }, $_[0] }
    sub isa { $_[1] eq 'IO::Socket::SSL' ? $_[0]->{ssl} : 0 }

    package MockLDAP;
    sub new    { bless { socket => MockSocket->new( $_[1] ) }, $_[0] }
    sub socket { $_[0]->{socket} }
    sub bind   { my $s = shift; $s->{args} = [@_]; return 'ok' }
}

sub bindArgs {
    my ( $ssl, $tls, %args ) = @_;
    my $ldap = MockLDAP->new($ssl);
    $package->new( \%args )->_bind( $ldap, $tls );
    return $ldap->{args};
}

my $r = bindArgs( 0, {}, ldapBindDN => 'cn=a', ldapBindPassword => '0' );
is_deeply( $r, [ 'cn=a', password => '0' ], 'simple bind, password "0"' );

$r = bindArgs( 1, { clientcert => '/c.pem' }, ldapBindDN => 'cn=a' );
is( $r->[0], 'cn=a', 'bind DN wins over client cert' );

SKIP: {
    skip 'Authen::SASL not installed', 3
      unless eval { require Authen::SASL };
    $r = bindArgs( 1, { clientcert => '/c.pem' } );
    is( $r->[0],            undef,      'SASL EXTERNAL: no DN' );
    is( $r->[1],            'sasl',     'SASL EXTERNAL: sasl arg' );
    is( $r->[2]->mechanism, 'EXTERNAL', 'SASL EXTERNAL mechanism' );
}

$r = bindArgs( 0, { clientcert => '/c.pem' } );
is_deeply( $r, [], 'no TLS + clientcert: anonymous' );

$r = bindArgs( 1, {} );
is_deeply( $r, [], 'TLS without clientcert: anonymous' );

$r = bindArgs( 0, {}, ldapBindDN => '' );
is_deeply( $r, [], 'empty DN: anonymous' );

ok( !$INC{'IO/Socket/Timeout.pm'}, 'IO::Socket::Timeout still not loaded' );

# Web::Session::LDAP helpers (no server needed)
my $browseable = 'Web::Session::LDAP';
use_ok($browseable);

# _cmpNum: exact comparison of decimal strings
foreach (
    [ 1,                  2,                  -1 ],
    [ 10,                 9,                   1 ],
    [ 99,                 1000,               -1 ],
    [ '0010',             10,                  0 ],
    [ '7.000',            7,                   0 ],
    [ '-0',               '0.0',               0 ],
    [ -1,                  0,                 -1 ],
    [ -10,                -9,                 -1 ],
    [ '0.5',              '0.45',              1 ],
    [ '-0.5',             '-0.45',            -1 ],
    [ '999.5',            1000,               -1 ],
    [ 1790000000,         1790000001,         -1 ],
    [ '9007199254740993', '9007199254740992',  1 ],
    [ " 12\n",            ' 12 ',              0 ],
  )
{
    is( $browseable->_cmpNum( $_->[0], $_->[1] ),
        $_->[2], "_cmpNum($_->[0], $_->[1])" );
}
foreach ( 'abc', '', ' ', undef, '1e3', '1 2', '1.', '.5', '+1', '0x10', [1] ) {
    my $d = defined $_ ? "'$_'" : 'undef';
    ok( !defined $browseable->_cmpNum( $_, 1 ), "_cmpNum: $d isn't a number" );
}

# _presenceFilter escapes the field name
is( $browseable->_presenceFilter( { ldapAttributeIndex => 'ou' }, '_utime' ),
    '(ou=_utime_*)', '_presenceFilter' );
is(
    $browseable->_presenceFilter( { ldapAttributeIndex => 'ou' }, 'a*b(c)\\' ),
    '(ou=a\2ab\28c\29\5c_*)',
    '_presenceFilter: escaped field'
);

# _lowerThanFilter
my $llngRule = {
    not => { _session_kind => 'Persistent' },
    or  => { _utime        => 1790560000, _lastSeen => 1790556400 },
};
my $fArgs = { Index => '_utime _lastSeen _session_kind uid' };
sub ltFilter { $browseable->_lowerThanFilter( {%$fArgs}, @_ ) }

is(
    ltFilter($llngRule),
    '(&(objectClass=applicationProcess)(|(ou=_lastSeen_*)(ou=_utime_*))'
      . '(!(ou=_session_kind_Persistent)))',
    '_lowerThanFilter: LLNG rule'
);
is(
    ltFilter( { and => { _utime => 1, _lastSeen => 2 } } ),
    '(&(objectClass=applicationProcess)(&(ou=_lastSeen_*)(ou=_utime_*)))',
    '_lowerThanFilter: and'
);
is(
    ltFilter( { or => { _utime => 1 }, not => undef } ),
    '(&(objectClass=applicationProcess)(ou=_utime_*))',
    '_lowerThanFilter: single field, no "not"'
);
is(
    ltFilter( { or => { _utime => " 1000\t" } } ),
    '(&(objectClass=applicationProcess)(ou=_utime_*))',
    '_lowerThanFilter: threshold spaces ignored'
);
is(
    ltFilter( { or => { _utime => ' 0 ' } } ),
    '(&(objectClass=applicationProcess)(ou=_utime_*))',
    '_lowerThanFilter: threshold " 0 " accepted'
);
is(
    ltFilter( { or => { _utime => 1 }, not => { uid => 'a*)(|(cn=*' } } ),
    '(&(objectClass=applicationProcess)(ou=_utime_*)'
      . '(!(ou=uid_a\2a\29\28|\28cn=\2a)))',
    '_lowerThanFilter: "not" value escaped'
);
is(
    $browseable->_lowerThanFilter(
        {
            %$fArgs,
            ldapObjectClass    => 'device',
            ldapAttributeIndex => 'l',
        },
        { or => { _utime => 1 } }
    ),
    '(&(objectClass=device)(l=_utime_*))',
    '_lowerThanFilter: custom objectClass and index attribute'
);

{
    # Rejected rules; hide "threshold must be a number" messages
    local *STDERR;
    open STDERR, '>', \my $err;
    foreach (
        [ undef, 'no rule' ],
        [ {},    'no or/and' ],
        [ { not => { uid => 'a' } }, 'only not' ],
        [ { or  => {} },             'empty or' ],
        [ { or  => [] },             'or is not a hash' ],
        [ { or  => { _utime => 1 }, and => { _utime => 1 } }, 'or + and' ],
        [ { or  => { _utime => 'abc' } },                     'threshold abc' ],
        [ { or  => { _utime => '1e3' } },                     'threshold 1e3' ],
        [ { or  => { _utime => ' 1e3 ' } }, 'threshold " 1e3 "' ],
        [ { or  => { _utime => '1 OR 1' } }, 'threshold 1 OR 1' ],
        [ { or  => { _utime => undef } },    'threshold undef' ],
        [ { or  => { foo => 1 } },           'field not indexed' ],
        [
            { or => { _utime => 1 }, not => { foo => 'a' } },
            '"not" not indexed'
        ],
        [ { or => { _utime => 1 }, not => { uid => '0' } }, '"not" 0' ],
        [ { or => { _utime => 1 }, not => { uid => '' } },  '"not" empty' ],
        [ { or => { _utime => 1 }, not => 'uid' }, '"not" not a hash' ],
      )
    {
        ok( !defined ltFilter( $_->[0] ), "_lowerThanFilter rejects $_->[1]" );
    }
}

# An unusable "not" value (empty or "0") is a silent fallback, not an error
{
    my $err = '';
    local *STDERR;
    open STDERR, '>', \$err;
    ok(
        !defined ltFilter( { or => { _utime => 1 }, not => { uid => '0' } } ),
        '_lowerThanFilter: "not" 0 rejected'
    );
    is( $err, '', '_lowerThanFilter: "not" 0 rejected without message' );
}

# _matchLowerThan
foreach (
    [ [qw(_utime_999)],                    1, 'lower' ],
    [ [qw(_utime_1790560000)],             0, 'equal' ],
    [ [qw(_utime_1790560001)],             0, 'greater' ],
    [ [qw(_utime_99)],                     1, 'shorter' ],
    [ [qw(_utime_10000000000)],            0, 'longer' ],
    [ [qw(_utime_0999999999)],             1, 'leading zero' ],
    [ [qw(_utime_1790559999.5)],           1, 'decimal' ],
    [ [qw(_utime_abc)],                    0, 'not a number' ],
    [ ['_utime_ 999 '],                    1, 'surrounding spaces' ],
    [ ['_utime_ 1790560000 '],            0, 'equal with spaces' ],
    [ ['_utime_ abc '],                    0, 'not a number with spaces' ],
    [ [qw(uid_dwho)],                      0, 'no field' ],
    [ [qw(_utime_x_1 _utimex_1)],          0, 'other fields with same prefix' ],
    [ [qw(_utime_1790560000 _lastSeen_1)], 1, 'or: second field lower' ],
    [ [qw(_utime_1 _session_kind_Persistent)],  0, 'not: excluded' ],
    [ [qw(_utime_1 _session_kind_SSO)],         1, 'not: other value' ],
    [ [qw(_utime_1 _session_kind_Persistent2)], 1, 'not: exact value' ],
  )
{
    is( $browseable->_matchLowerThan( $llngRule, @{ $_->[0] } ) ? 1 : 0,
        $_->[1], "_matchLowerThan (or): $_->[2]" );
}
my $andRule = { and => { _utime => 100, _lastSeen => 100 } };
foreach (
    [ [qw(_utime_1 _lastSeen_1)],   1, 'both lower' ],
    [ [qw(_utime_1 _lastSeen_100)], 0, 'one equal' ],
    [ [qw(_utime_1)],               0, 'one missing' ],
  )
{
    is( $browseable->_matchLowerThan( $andRule, @{ $_->[0] } ) ? 1 : 0,
        $_->[1], "_matchLowerThan (and): $_->[2]" );
}

# _lowerThanAssertion: observed rule values, "not" values still missing
is(
    $browseable->_lowerThanAssertion(
        { ldapAttributeIndex => 'ou' },
        $llngRule,
        qw(_utime_5 uid_dwho _lastSeen_4 _session_kind_SSO)
    ),
    '(&(ou=_lastSeen_4)(ou=_utime_5)(!(ou=_session_kind_Persistent)))',
    '_lowerThanAssertion'
);
is(
    $browseable->_lowerThanAssertion(
        { ldapAttributeIndex => 'ou' },
        { and                => { a => 1 }, not => { b => 'x*' } },
        'a_1)(x', 'b_y'
    ),
    '(&(ou=a_1\29\28x)(!(ou=b_x\2a)))',
    '_lowerThanAssertion: escaped values'
);

# _pagedSearch: page loop guards
{

    package MockPagedResponse;
    sub new    { bless { cookie => $_[1] }, $_[0] }
    sub cookie { $_[0]->{cookie} }

    package MockSearchResult;
    sub new {
        my ( $class, $entries, $cookie ) = @_;
        bless {
            entries => $entries,
            paged   => defined $cookie ? MockPagedResponse->new($cookie) : undef,
        }, $class;
    }
    sub code    {0}
    sub count   { scalar @{ $_[0]->{entries} } }
    sub entries { @{ $_[0]->{entries} } }
    sub control { $_[0]->{paged} ? ( $_[0]->{paged} ) : () }

    package MockPagedLDAP;
    sub new  { bless { pages => [ @_[ 1 .. $#_ ] ], i => 0 }, $_[0] }
    sub search { my $self = shift; return $self->{pages}->[ $self->{i}++ ] }
}

# Runs _pagedSearch on fake pages, returns the collected entries and STDERR
sub pagedSearchRun {
    my ( $pages, $size ) = @_;
    local $Web::Session::LDAP::PageSize = $size
      if defined $size;
    my @seen;
    my $err = '';
    {
        local *STDERR;
        open STDERR, '>', \$err;
        $browseable->_pagedSearch( MockPagedLDAP->new(@$pages),
            sub { push @seen, $_[0] }, base => 'x' );
    }
    return ( \@seen, $err );
}

# Normal pagination: last page has an empty cookie
my ( $entries, $err ) = pagedSearchRun(
    [
        MockSearchResult->new( [ 'a', 'b' ], 'x' ),
        MockSearchResult->new( ['c'],       'y' ),
        MockSearchResult->new( [],          '' ),
    ],
    undef
);
is_deeply( $entries, [ 'a', 'b', 'c' ], '_pagedSearch: all pages read' );
is( $err, '', '_pagedSearch: no warning' );

# Constant cookie would loop forever
( $entries, $err ) = pagedSearchRun(
    [
        MockSearchResult->new( ['a'], 'x' ),
        MockSearchResult->new( ['b'], 'x' ),
    ],
    undef
);
is_deeply( $entries, [ 'a', 'b' ], '_pagedSearch: constant cookie stops' );
like( $err, qr/cookie didn't change/, '_pagedSearch: constant cookie warned' );

# No response control with a full page: result may be truncated
( $entries, $err ) = pagedSearchRun( [ MockSearchResult->new( [ 'a', 'b' ] ) ],
    2 );
is_deeply( $entries, [ 'a', 'b' ], '_pagedSearch: no control, full page' );
like( $err, qr/no paged results control/,
    '_pagedSearch: full page without control warned' );

# No response control with a partial page: everything was returned
( $entries, $err ) = pagedSearchRun( [ MockSearchResult->new( ['a'] ) ], 2 );
is_deeply( $entries, ['a'], '_pagedSearch: no control, partial page' );
is( $err, '', '_pagedSearch: partial page without control, no warning' );

# deleteIfLowerThan: unusable rules keep the (ok, count) contract
{
    local *STDERR;
    open STDERR, '>', \my $err;
    my @r = $browseable->deleteIfLowerThan( { Index => 'uid _utime' },
        { or => { foo => 1 } } );
    is_deeply( \@r, [ 0, 0 ], 'deleteIfLowerThan: bad rule returns ( 0, 0 )' );
    ok(
        !$browseable->deleteIfLowerThan( { Index => 'uid _utime' },
            { or => { foo => 1 } } ),
        'deleteIfLowerThan: bad rule false in scalar context'
    );
}

# deleteIfLowerThan: LDAP errors on a mocked connection
{

    package MockEntry;
    sub new { my $c = shift; bless [@_], $c }
    sub dn  { $_[0]->[0] }
    sub get_value { my $s = shift; @$s[ 1 .. $#$s ] }

    package MockResult;
    sub new   { bless { code => $_[1] }, $_[0] }
    sub code  { $_[0]->{code} }
    sub error { 'mock error' }

    package MockDeleteLDAP;
    sub new { bless { deletes => [], code => $_[1] }, $_[0] }
    sub search {
        my ( $self, %s ) = @_;
        return MockResult->new( $self->{searchCode} )
          if ( $s{scope} eq 'base' and $self->{searchCode} );
        return MockSearchResult->new(
            [ MockEntry->new( 'cn=a', '_utime_5' ),
              MockEntry->new( 'cn=b', '_utime_5' ) ]
        );
    }
    sub delete {
        my ( $self, $dn, %o ) = @_;
        push @{ $self->{deletes} }, [ $dn, @{ $o{control} } ];
        return MockResult->new( @{ $self->{deletes} } > 1 ? $self->{code} : 0 );
    }
    sub unbind     { }
    sub disconnect { }
}

sub mockedDelete {
    my ( $ldap, $rule, $list ) = @_;
    no warnings 'redefine';
    local *Web::Session::Store::LDAP::ldap = sub { $ldap };
    my ( @r, $err );
    $err = '';
    local *STDERR;
    open STDERR, '>', \$err;
    my $ok = $list ? [ $browseable->deleteIfLowerThan( { Index => 'uid _utime _session_kind' }, $rule ) ]
                   : scalar $browseable->deleteIfLowerThan( { Index => 'uid _utime _session_kind' }, $rule );
    return ( $ok, $err );
}

# Server without assertion control support: stop, return the deleted count
my $mock = MockDeleteLDAP->new(12);
my ( $r, $mockErr ) = mockedDelete( $mock, { or => { _utime => 10 } }, 1 );
is_deeply( $r, [ 0, 1 ], 'deleteIfLowerThan: critical extension error, ( 0, 1 )' );
is( scalar @{ $mock->{deletes} }, 2, '... stops at the first failure' );
like( $mockErr, qr/LDAP error 12/, '... reports the error' );
like( $mockErr, qr/assertion control/, '... and the missing control' );
is( scalar( () = $mockErr =~ /assertion control/g ), 1, '... only once' );
ok( $mock->{deletes}->[0]->[1]->critical, 'Assertion control is critical' );

$mock = MockDeleteLDAP->new(12);
( $r, $mockErr ) = mockedDelete( $mock, { or => { _utime => 10 } }, 0 );
is( $r, 0, 'deleteIfLowerThan: critical extension error, false in scalar' );

# Error while reading a session without "not" index: nothing deleted
$mock = MockDeleteLDAP->new(0);
$mock->{searchCode} = 50;
( $r, $mockErr ) = mockedDelete(
    $mock,
    { or => { _utime => 10 }, not => { _session_kind => 'Persistent' } }, 1
);
is_deeply( $r, [ 0, 0 ], '_notInContent search error: ( 0, 0 )' );
is( scalar @{ $mock->{deletes} }, 0, '... nothing deleted' );
like( $mockErr, qr/LDAP error 50: mock error/, '... and reported' );
