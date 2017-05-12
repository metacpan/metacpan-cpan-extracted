use Test::More;
use Test::Mock::Redis;
use Tie::Redis::Candy qw(redis_hash);
use Scalar::Util qw(reftype refaddr);

my $redis = Test::Mock::Redis->new( server => 'localhost' );

$redis->del('H');
plan tests => 24;

my $W = redis_hash( $redis, 'H', init_W => 'x', foo => 1 );

is ref($W)     => 'Tie::Redis::Candy::Hash';
is reftype($W) => 'HASH';

ok exists $W->{foo};
is $W->{foo} => 1;

my $R = redis_hash( $redis, 'H', init_R => 'y', foo => 2 );

is ref($R)     => 'Tie::Redis::Candy::Hash';
is reftype($R) => 'HASH';
isnt refaddr($R), refaddr($W);

is $R->{foo} => 2;
is $W->{foo} => 2;

ok $W->{scalar} = 42;
is $R->{scalar}, 42;

ok $W->{hash} = { a => 16 };
is $R->{hash}->{a}, 16;

ok not exists( $R->{nonexistent} );
is $R->{nonexistent} => undef;
ok not exists( $R->{nonexistent} );

ok exists $R->{foo};
ok exists $W->{foo};
delete $W->{foo};
ok not exists $R->{foo};
ok not exists $W->{foo};

is_deeply [ sort keys %$R ] => [ sort qw[ hash init_R init_W scalar ] ];

is_deeply $R => {
    scalar => 42,
    hash   => { a => 16 },
    init_W => 'x',
    init_R => 'y',
};

ok scalar(%$R);
%$W = ();
ok not scalar(%$R);

done_testing;
