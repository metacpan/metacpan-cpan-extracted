use Test2::V0;

use Zuzu::Util::Number qw( is_finite_number );

my $positive_infinity = unpack 'd>', pack 'H*', '7ff0000000000000';
my $negative_infinity = unpack 'd>', pack 'H*', 'fff0000000000000';
my $nan = unpack 'd>', pack 'H*', '7ff8000000000000';
my $max_finite = unpack 'd>', pack 'H*', '7fefffffffffffff';

ok is_finite_number(0), 'zero is finite';
ok is_finite_number(-1), 'negative integer is finite';
ok is_finite_number(3.25), 'fractional number is finite';
ok is_finite_number($max_finite), 'largest binary64 finite value is finite';

ok !is_finite_number($positive_infinity), 'positive infinity is not finite';
ok !is_finite_number($negative_infinity), 'negative infinity is not finite';
ok !is_finite_number($nan), 'NaN is not finite';

done_testing;
