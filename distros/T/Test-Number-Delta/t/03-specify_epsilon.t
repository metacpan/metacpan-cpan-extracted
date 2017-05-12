use strict;

use Test::Builder::Tester tests => 2;
use Test::Number::Delta within  => 1e-4;

test_out("not ok 1 - foo");
test_fail(+2);
test_diag("0.00100 and 0.00200 are not equal to within 0.0001");
delta_ok( 1e-3, 2e-3, "foo" );
test_test("fail works");

test_out("ok 1 - foo");
delta_ok( 1.1e-4, 2e-4, "foo" );
test_test("ok works");

