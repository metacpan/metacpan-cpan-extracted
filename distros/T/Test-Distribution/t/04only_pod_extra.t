use Test::Distribution
    tests => 2,
    only  => [ 'pod' ];
use Test::More;
ok(1, 'extra test');

# 1 * (1 module) + 2 extra
is(Test::Distribution::num_tests(), 3, 'number of tests');
