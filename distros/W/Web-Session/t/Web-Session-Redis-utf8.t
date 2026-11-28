use strict;
use warnings;
use Test::More;

my $class = 'Web::Session::Redis';

plan skip_all => 'Redis module is needed' unless eval "require $class";

my $latin = "\x{c9}lodie";
my $emoji = "\x{3a9}\x{20ac} \x{1f600}";

# Key names: Latin-1 bytes when possible (existing sets), else UTF-8 bytes
my $keyName = \&Web::Session::Store::Redis::keyName;
is( $keyName->('uid_dwho'),    'uid_dwho',  'keyName: ASCII' );
is( $keyName->("uid_m\x{e9}"), "uid_m\xe9", 'keyName: Latin-1' );
ok( !utf8::is_utf8( $keyName->("uid_m\x{e9}") ), 'keyName: Latin-1 bytes' );
is( $keyName->("uid_\x{3a9}"), "uid_\xce\xa9", 'keyName: UTF-8' );
is( $keyName->("\x{e9}_\x{20ac}"),
    "\xc3\xa9_\xe2\x82\xac", 'keyName: whole name in UTF-8' );
is( $keyName->("uid_\x{1f600}"), "uid_\xf0\x9f\x98\x80", 'keyName: emoji' );
is( $keyName->(42),              '42',                   'keyName: number' );
{
    my $s = "uid_\x{3a9}";
    $keyName->($s);
    is( $s, "uid_\x{3a9}", 'keyName: argument unchanged' );
}
my $patterns = $class->can('_exprPatterns');
is_deeply(
    [ $patterns->( 'uid', "m\x{e9}*" ) ],
    [ "uid_m\xe9*", "uid_m\xc3\xa9*" ],
    'patterns: Latin-1 and UTF-8'
);
is_deeply( [ $patterns->( 'uid', 'jd*' ) ], ['uid_jd*'], 'patterns: ASCII' );
is_deeply( [ $patterns->( 'uid', "m\x{e9}" ) ],
    ["uid_m\xe9"], 'patterns: no wildcard' );
is_deeply( [ $patterns->( 'uid', "\x{3a9}*" ) ],
    ["uid_\xce\xa9*"], 'patterns: wide characters' );

# serializeLatin1(): the result can always be downgraded to Latin-1 bytes
sub ser {
    my $s = { data => shift };
    Web::Session::Serialize::JSON::serializeLatin1($s);
}

sub unser {
    my $s = { serialized => shift };
    Web::Session::Serialize::JSON::unserialize($s);
    $s->{data};
}
{
    my $l = { sn   => $latin, cn => "\x{e9}\x{ff}" };
    my $s = { data => $l };
    Web::Session::Serialize::JSON::serialize($s);
    my $old = $s->{serialized};
    utf8::downgrade($old);
    my $new = ser($l);
    ok( utf8::downgrade( $new, 1 ), 'serializeLatin1: Latin-1 downgrade' );
    is( $new, $old, 'serializeLatin1: same as serialize for Latin-1 data' );
    my $d   = { cn => $emoji, sn => $latin, l => [$emoji] };
    my $got = ser($d);
    ok( utf8::downgrade( my $c = $got, 1 ), 'serializeLatin1: downgrade' );
    unlike( $got, qr/[\x{100}-\x{10ffff}]/, 'serializeLatin1: only escapes' );
    like(
        $got,
        qr/\\u03a9\\u20ac \\ud83d\\ude00/i,
        'serializeLatin1: escapes, surrogate pair'
    );
    is_deeply( unser($got), $d, 'serializeLatin1: round trip' );
    utf8::downgrade($got);
    is_deeply( unser($got), $d,
        'serializeLatin1: round trip of Latin-1 bytes' );
}

unless ( $ENV{REDIS_URL} ) {
    done_testing();
    exit;
}

# Not the databases of the other Redis tests, to run them in parallel
my $args = {
    server   => $ENV{REDIS_URL},
    database => ( ( $ENV{REDIS_DBNUM} || 15 ) + 12 ) % 16,
    Index    => 'uid cn',
};
my $redis = $class->_getRedis($args);
$redis->flushdb;

my $new = sub {
    my %data = @_;
    my %session;
    my @warn;
    local $SIG{__WARN__} = sub { push @warn, @_ };
    tie %session, $class, undef, $args;
    $session{$_} = $data{$_} foreach ( keys %data );
    my $id = $session{_session_id};
    untie %session;
    is_deeply( \@warn, [], 'Session saved without warning' );
    return $id;
};

# Round trip
my $wide = $new->( uid => $emoji, cn => $emoji, l => [$emoji], sn => $latin );
{
    my %session;
    tie %session, $class, $wide, $args;
    is( $session{cn}, $emoji, 'Wide characters: value saved' );
    is_deeply( $session{l}, [$emoji], 'Wide characters: array saved' );
    is( $session{sn}, $latin, 'Wide characters: Latin-1 value kept' );
    untie %session;
    my $r = $class->get_key_from_all_sessions($args);
    is( $r->{$wide}->{cn},
        $emoji, 'Wide characters: get_key_from_all_sessions' );
}

# Index entry of the previous value must be removed on update
foreach my $t (
    [ $emoji, 'toto' ],
    [ 'toto', $emoji ],
    [ $emoji, "\x{20ac}", cn => $emoji ],
  )
{
    my ( $old, $nv, %data ) = @$t;
    ( my $l = "$old -> $nv" ) =~ s/[^ -~]/?/g;
    my $id = $new->( uid => $old, %data );
    ok( $redis->sismember( $keyName->("uid_$old"), $id ), "Index $l: added" );
    my %session;
    tie %session, $class, $id, $args;
    $session{uid} = $nv;
    untie %session;
    ok( !$redis->sismember( $keyName->("uid_$old"), $id ),
        "Index $l: old removed" );
    ok( $redis->sismember( $keyName->("uid_$nv"), $id ),
        "Index $l: new added" );
    tie %session, $class, $id, $args;
    tied(%session)->delete;
}

# Search on values above U+00FF
my $omega = "\x{3a9}";
my $om    = $new->( uid => $omega );
my $lat   = $new->( uid => "m\x{e9}" );

# "\x{3a9}" in UTF-8 is "\x{ce}\x{a9}", which is also a Latin-1 value
my $coll = $new->( uid => "\x{ce}\x{a9}" );
my $r    = $class->searchOn( $args, 'uid', $emoji, 'cn' );
is_deeply( [ keys %$r ], [$wide], 'Wide characters: searchOn' );
is( $r->{$wide}->{cn}, $emoji, 'Wide characters: searchOn with fields' );
$r = $class->searchOn( $args, 'cn', $emoji );
is_deeply( [ keys %$r ], [$wide], 'Wide characters: searchOn on cn' );
$r = $class->searchOnExpr( $args, 'uid', "\x{3a9}*" );
ok( $r->{$wide} && $r->{$om}, 'Wide characters: searchOnExpr prefix' );
$r = $class->searchOnExpr( $args, 'uid', "*\x{1f600}" );
is_deeply( [ keys %$r ], [$wide], 'Wide characters: searchOnExpr suffix' );
$r = $class->searchOnExpr( $args, 'uid', 'm*' );
ok( $r->{$lat},   'Latin-1 value: searchOnExpr' );
ok( !$r->{$wide}, 'Latin-1 value: searchOnExpr, wide value skipped' );
$r = $class->searchOn( $args, 'uid', "m\x{e9}" );
is_deeply( [ keys %$r ], [$lat], 'Latin-1 value: searchOn' );
$r = $class->searchOnExpr( $args, 'uid', "\x{3a9}*" );
ok( !$r->{$coll}, 'Wide characters: searchOnExpr, other value skipped' );
$r = $class->searchOn( $args, 'uid', $omega );
is_deeply( [ keys %$r ], [$om], 'Colliding names: wide value' );
$r = $class->searchOn( $args, 'uid', "\x{ce}\x{a9}" );
is_deeply( [ keys %$r ], [$coll], 'Colliding names: Latin-1 value' );

$redis->flushdb;
done_testing();
