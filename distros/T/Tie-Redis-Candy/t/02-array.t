use Test::More;
use Test::Mock::Redis;
use Tie::Redis::Candy qw(redis_array);
use Scalar::Util qw(reftype refaddr);

my $redis = Test::Mock::Redis->new( server => 'localhost' );

$redis->del('A');
plan tests => 23;

my $W = redis_array( $redis, 'A', 1, 2, );
is ref($W)     => 'Tie::Redis::Candy::Array';
is reftype($W) => 'ARRAY';

is $W->[0] => 1;
is $W->[1] => 2;
is $W->[2] => undef;

is scalar(@$W) => 2;

my $R = redis_array( $redis, 'A', 3, 4 );
is ref($W)     => 'Tie::Redis::Candy::Array';
is reftype($W) => 'ARRAY';

isnt refaddr($R) => refaddr($W);

is scalar(@$R) => 4;
is scalar(@$W) => 4;

is_deeply( $R, $W );
is_deeply( $W, $R );

$W->[2] = 9;
is_deeply( $R => [qw[ 1 2 9 4 ]] ) or diag explain $R;

$W->[-2] = 3;
is_deeply( $R => [qw[ 1 2 3 4 ]] ) or diag explain $R;

push @$W => 5, 6;
is_deeply( $R => [qw[ 1 2 3 4 5 6 ]] ) or diag explain $R;

ok pop @$W;
is_deeply( $R => [qw[ 1 2 3 4 5 ]] ) or diag explain $R;

unshift @$W => -1, 0;
is_deeply( $R => [qw[ -1 0 1 2 3 4 5 ]] ) or diag explain $R;

shift @$W;
is_deeply( $R => [qw[ 0 1 2 3 4 5 ]] ) or diag explain $R;

@$W = ();
is scalar(@$R) => 0;
is scalar(@$W) => 0;
is_deeply( $R => [] ) or diag explain $R;

done_testing;
