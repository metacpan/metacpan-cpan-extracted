use strict;
use warnings;
use Test::More;

my $class = 'Web::Session::Redis';

plan skip_all => 'Redis module is needed' unless eval "require $class";

# deleteIfLowerThan decision: only a missing _utime means "expired"
my $dom = $class->can('_isDominated');
my $sid = { _session_id => 'x' };
my $or  = { or          => { _utime => 100, _lastSeen => 100 } };
my $and = { and         => { _utime => 100, _lastSeen => 100 } };
ok( $dom->( $class, {},    $or ),  'empty session is dominated' );
ok( $dom->( $class, undef, $and ), 'undef session is dominated' );
ok(
    $dom->( $class, { uid => 'a' }, $or ),
    'session without _session_id is dominated'
);
ok(
    !$dom->( $class, { %$sid, _utime => 200 }, $or ),
    'or: recent _utime, no _lastSeen: kept'
);
ok(
    $dom->( $class, { %$sid, _utime => 50 }, $or ),
    'or: old _utime, no _lastSeen: dominated'
);
ok( $dom->( $class, { %$sid, _lastSeen => 50, _utime => 200 }, $or ),
    'or: old _lastSeen: dominated' );
ok( $dom->( $class, { %$sid, _lastSeen => 200 }, $or ),
    'or: no _utime: dominated' );
ok( !$dom->( $class, { %$sid, _utime => 200, _lastSeen => 200 }, $or ),
    'or: recent session kept' );
ok( !$dom->( $class, { %$sid, _utime => 50 }, $and ),
    'and: missing _lastSeen: kept' );
ok( $dom->( $class, { %$sid, _utime => 50, _lastSeen => 50 }, $and ),
    'and: all lower: dominated' );
ok( !$dom->( $class, { %$sid, _utime => 50, _lastSeen => 150 }, $and ),
    'and: one not lower: kept' );
ok( $dom->( $class, { %$sid, _lastSeen => 50 }, $and ),
    'and: missing _utime counts as lower' );
ok( !$dom->( $class, { %$sid, _utime => 50 }, {} ), 'no rule: kept' );

# Invalid rules are rejected before connecting, like the SQL backends
{
    my $err = '';
    local *STDERR;
    open STDERR, '>', \$err;
    my $args = { server => '127.0.0.1:1' };
    foreach my $bad (
        [ 'not a hash ref'        => 'x' ],
        [ 'or is not a hash ref'  => { or  => 'x' } ],
        [ 'not is not a hash ref' => { not => [] } ],
        [ 'non numeric threshold' => { or  => { _utime => '1 OR 1' } } ],
      )
    {
        my ( $name, $rule ) = @$bad;
        my @r = $class->deleteIfLowerThan( $args, $rule );
        is_deeply( \@r, [ 0, 0 ], "invalid rule ($name): list context" );
        my $r = $class->deleteIfLowerThan( $args, $rule );
        is( $r, 0, "invalid rule ($name): scalar context" );
    }
    like( $err, qr/deleteIfLowerThan:/, 'invalid rules are reported' );
}

done_testing();
