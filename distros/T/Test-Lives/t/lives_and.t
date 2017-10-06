use strict;
use warnings;
use Test::Builder::Tester tests => 3;
use Test::More;
use Test::Lives;

test_out 'ok 1 - lives and succeeds';
lives_and { is 42, 42, $_ } 'lives and succeeds';

test_test 'pass one test when it lives and succeeds';

test_out 'not ok 1 - lives and fails';
test_fail +3;
test_diag "         got: '42'";
test_diag "    expected: '24'";
lives_and { is 42, 24, $_ } 'lives and fails';

test_test 'fail one test when it lives and fails';

test_out 'not ok 1 - dies';
test_fail +2;
test_diag "oops at ${\__FILE__} line ${\(__LINE__+1)}.";
lives_and { is die('oops'), 42, $_ } 'dies';

test_test 'fail one test when it dies';
