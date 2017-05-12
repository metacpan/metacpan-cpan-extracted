use Test::Distribution
    tests => 1,
    only  => 'prereq';
use Test::More;

# 1 prereq + 1 extra
is(Test::Distribution::num_tests(), 2, 'number of tests');
