use strict;
use warnings;
use Test::More;

my $class = 'Web::Session::Redis';

plan skip_all => 'Redis module is needed' unless eval "require $class";

# Fake client: pipelined SMEMBERS, MGET
{

    package FakePipe;
    our ( @log, %sets, %vals, $fail );
    sub new { bless { cbs => [] }, shift }

    sub smembers {
        my ( $self, $set, $cb ) = @_;
        push @log,              "smembers $set";
        push @{ $self->{cbs} }, sub {
            $fail                  ? $cb->( undef, $fail )
              : exists $sets{$set} ? $cb->( $sets{$set} )
              :                      $cb->( undef, 'WRONGTYPE bad' );
        };
    }

    sub wait_all_responses {
        push @log, 'wait';
        $_->() foreach @{ $_[0]->{cbs} };
        $_[0]->{cbs} = [];
    }

    sub mget {
        shift;
        push @log, 'mget ' . scalar(@_);
        map { $vals{$_} } @_;
    }
}
{
    no warnings 'once';
    local $Web::Session::Redis::MGET_BATCH = 2;
    my $r = FakePipe->new;
    %FakePipe::vals = map { $_ => "v$_" } 1 .. 5;
    is_deeply( [ $class->can('_mget')->( $r, 1 .. 5 ) ],
        [qw(v1 v2 v3 v4 v5)], '_mget: values in order' );
    is_deeply(
        \@FakePipe::log,
        [ 'mget 2', 'mget 2', 'mget 1' ],
        '_mget: batches'
    );

    @FakePipe::log  = ();
    %FakePipe::sets = ( s1 => [ 'a', 'b' ], s2 => ['a'] );
    is_deeply(
        $class->can('_smembers')->( $r, [qw(s1 s2 s3)] ),
        { s1 => [ 'a', 'b' ], s2 => ['a'] },
        '_smembers: members per set, wrong type ignored'
    );
    is_deeply(
        \@FakePipe::log,
        [ 'smembers s1', 'smembers s2', 'smembers s3', 'wait' ],
        '_smembers: one pipeline'
    );
    $FakePipe::fail = 'ERR timeout';
    ok( !eval { $class->can('_smembers')->( $r, [qw(s1 s2)] ); 1 },
        '_smembers: other errors are fatal' );
    like( $@, qr/timeout/, '_smembers: error message' );
}

unless ( $ENV{REDIS_URL} ) {
    done_testing();
    exit;
}

# Not the databases of the other Redis tests, to run them in parallel
my $args = {
    server   => $ENV{REDIS_URL},
    database => ( ( $ENV{REDIS_DBNUM} || 15 ) + 13 ) % 16,
    Index    => 'uid cn',
};
my $redis = $class->_getRedis($args);
$redis->flushdb;

# Several SCAN pages and MGET batches
{
    no warnings 'once';
    local $Web::Session::Redis::SCAN_COUNT = 2;
    local $Web::Session::Redis::MGET_BATCH = 3;
    my %all;
    foreach my $i ( 1 .. 30 ) {
        my %session;
        tie %session, $class, undef, $args;
        $session{uid}                 = "page$i";
        $session{cn}                  = 'sameCn';
        $all{ $session{_session_id} } = "page$i";
        untie %session;
    }
    is( scalar keys %{ $class->searchOnExpr( $args, 'uid', 'page*' ) },
        30, 'SCAN over several pages' );
    is( scalar keys %{ $class->searchOn( $args, 'cn', 'sameCn' ) },
        30, 'MGET in several batches' );
    is( scalar keys %{ $class->searchOnExpr( $args, 'cn', 'same*' ) },
        30, 'SCAN + MGET batches' );

    # Orphans are removed, members that aren't strings are kept
    my ( $orphan, $hashKey ) = ( 'f' x 64, 'e' x 64 );
    $redis->hset( $hashKey, a => 'b' );
    $redis->sadd( 'cn_sameCn', $orphan, $hashKey );
    is( scalar keys %{ $class->searchOn( $args, 'cn', 'sameCn' ) },
        30, 'searchOn: orphan and hash member skipped' );
    ok( !$redis->sismember( 'cn_sameCn', $orphan ),
        'searchOn: orphan removed' );
    ok( $redis->sismember( 'cn_sameCn', $hashKey ),
        'searchOn: hash member kept' );
    $redis->sadd( 'cn_sameCn', $orphan );
    is( scalar keys %{ $class->searchOnExpr( $args, 'cn', 'same*' ) },
        30, 'searchOnExpr: orphan and hash member skipped' );
    ok( !$redis->sismember( 'cn_sameCn', $orphan ),
        'searchOnExpr: orphan removed' );
    ok( $redis->sismember( 'cn_sameCn', $hashKey ),
        'searchOnExpr: hash member kept' );
}

$redis->flushdb;
done_testing();
