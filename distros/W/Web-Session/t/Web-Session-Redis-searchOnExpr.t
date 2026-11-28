use strict;
use warnings;
use utf8;
use Test::More;

my $class = 'Web::Session::Redis';

plan skip_all => 'Redis module is needed' unless eval "require $class";

# SCAN patterns: '*' is the only wildcard of the value
my $pattern = $class->can('_exprPattern');
is( $pattern->( 'uid', 'jdoe' ), 'uid_jdoe', 'pattern: plain' );
is( $pattern->( 'uid', 'jd*' ),  'uid_jd*',  'pattern: wildcard' );
is( $pattern->( 'uid', 'CORP\\jd*' ),
    'uid_CORP\\\\jd*', 'pattern: backslash in value' );
is(
    $pattern->( 'uid', 'a?[b]' ),
    'uid_a\\?\\[b\\]',
    'pattern: glob chars in value'
);
is( $pattern->( 'u?[*]\\d', 'x' ),
    'u\\?\\[\\*\\]\\\\d_x', 'pattern: glob chars in field name' );
is( $class->can('_globEscape')->('a*b'), 'a\\*b', '_globEscape' );

unless ( $ENV{REDIS_URL} ) {
    done_testing();
    exit;
}

# Not the databases of the other Redis tests, to run them in parallel
my $args = {
    server   => $ENV{REDIS_URL},
    database => ( ( $ENV{REDIS_DBNUM} || 15 ) + 14 ) % 16,
    Index    => 'uid cn u?x',
};
my $redis = $class->_getRedis($args);
$redis->flushdb;

my %ids;
foreach my $u (
    [ 'CORP\jdoe',   'John' ],
    [ 'CORP\jsmith', 'Jane' ],
    [ 'CORP\other',  'Other' ],
    [ 'CORPxjdoe',   'X' ],
    [ 'a?c',         'Q' ],
    [ 'abc',         'B' ],
    [ 'a[b]',        'Br' ],
    [ 'élodie',      'Élodie' ],
  )
{
    my %session;
    tie %session, $class, undef, $args;
    $session{uid}                 = $u->[0];
    $session{cn}                  = $u->[1];
    $session{'u?x'}               = $u->[0];
    $ids{ $session{_session_id} } = $u->[0];
    untie %session;
}
my $names = sub {
    [ sort map { $ids{$_} } keys %{ $_[0] } ]
};

is_deeply( $names->( $class->searchOnExpr( $args, 'uid', 'CORP\jd*' ) ),
    ['CORP\jdoe'], 'backslash in value' );
is_deeply(
    $names->( $class->searchOnExpr( $args, 'uid', 'CORP\*' ) ),
    [ 'CORP\jdoe', 'CORP\jsmith', 'CORP\other' ],
    'backslash before wildcard'
);
is_deeply( $names->( $class->searchOnExpr( $args, 'uid', 'a?c' ) ),
    ['a?c'], '? is not a wildcard' );
is_deeply( $names->( $class->searchOnExpr( $args, 'uid', 'a[b]' ) ),
    ['a[b]'], 'brackets are literal' );
is_deeply(
    $names->( $class->searchOnExpr( $args, 'u?x', 'a*' ) ),
    [ 'a?c', 'a[b]', 'abc' ],
    'field name with ?'
);
is_deeply( $names->( $class->searchOn( $args, 'uid', 'CORP\jdoe' ) ),
    ['CORP\jdoe'], 'searchOn with backslash' );
is_deeply( $names->( $class->searchOn( $args, 'uid', 'élodie' ) ),
    ['élodie'], 'searchOn with non-ASCII value' );
is_deeply( $names->( $class->searchOnExpr( $args, 'uid', 'él*' ) ),
    ['élodie'], 'searchOnExpr with non-ASCII value' );
my ($id) = keys %{ $class->searchOn( $args, 'cn', 'Élodie' ) };
is( $ids{$id}, 'élodie', 'searchOn with non-ASCII index name' );

# "a_b" + "c" and "a" + "b_c" share the index set "a_b_c"
{
    my $args2 = { %$args, Index => 'a a_b' };
    my %cid;
    foreach ( [ ab => a => 'b_c' ], [ abc => a_b => 'c' ] ) {
        my %session;
        tie %session, $class, undef, $args2;
        $session{ $_->[1] } = $_->[2];
        $cid{ $session{_session_id} } = $_->[0];
        untie %session;
    }
    my $res = $class->searchOn( $args2, 'a', 'b_c' );
    is_deeply( [ map { $cid{$_} } keys %$res ],
        ['ab'], 'searchOn: session of the other field ignored' );
    $res = $class->searchOnExpr( $args2, 'a', 'b_*' );
    is_deeply( [ map { $cid{$_} } keys %$res ],
        ['ab'], 'searchOnExpr: session of the other field ignored' );
}

$redis->flushdb;
done_testing();
