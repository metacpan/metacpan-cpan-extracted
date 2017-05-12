use strict;

use Test::Builder::Tester 1.02 tests => 25;
use Test::Number::Delta;

select(STDERR);
$|++;
select(STDOUT);
$|++;

#--------------------------------------------------------------------------#
# scalar - delta_ok
#--------------------------------------------------------------------------#

test_out("not ok 1 - foo");
test_fail(+2);
test_diag("0.0000100 and 0.0000200 are not equal to within 0.000001");
delta_ok( 1e-5, 2e-5, "foo" );
test_test("delta_ok(\$a,\$b) fail works");

test_out("ok 1 - foo");
delta_ok( 1.1e-6, 2e-6, "foo" );
test_test("delta_ok(\$a,\$b) pass works");

#--------------------------------------------------------------------------#
# scalar - delta_not_ok
#--------------------------------------------------------------------------#

test_out("not ok 1 - foo");
test_fail(+2);
test_diag("Arguments are equal to within 0.000001");
delta_not_ok( 1e-7, 2e-7, "foo" );
test_test("delta_not_ok(\$a,\$b) fail works");

test_out("ok 1 - foo");
delta_not_ok( 1.2e-5, 1e-5, "foo" );
test_test("delta_not_ok(\$a,\$b) pass works");

#--------------------------------------------------------------------------#
# scalar -- delta_within
#--------------------------------------------------------------------------#

test_out("not ok 1 - foo");
test_fail(+2);
test_diag("0.00100 and 0.00200 are not equal to within 0.0001");
delta_within( 1e-3, 2e-3, 1e-4, "foo" );
test_test("delta_within(\$a,\$b,\$e) fail works");

test_out("not ok 1 - foo");
test_fail(+2);
test_diag("0.00100 and 0.00200 are not equal to within 0.0001");
delta_within( 1e-3, 2e-3, -1e-4, "foo" );
test_test("delta_within(\$a,\$b,-\$e) fail works");

test_out("ok 1 - foo");
delta_within( 1.1e-4, 2e-4, 1e-4, "foo" );
test_test("delta_within(\$a,\$b,\$e) pass works");

test_out("ok 1 - foo");
delta_within( 1.1e-4, 2e-4, -1e-4, "foo" );
test_test("delta_within(\$a,\$b,-\$e) pass works");

#--------------------------------------------------------------------------#
# scalar -- delta_not_within
#--------------------------------------------------------------------------#

test_out("not ok 1 - foo");
test_fail(+2);
test_diag("Arguments are equal to within 0.01");
delta_not_within( 1e-3, 2e-3, 1e-2, "foo" );
test_test("delta_not_within(\$a,\$b,\$e) fail works");

test_out("not ok 1 - foo");
test_fail(+2);
test_diag("Arguments are equal to within 0.01");
delta_not_within( 1e-3, 2e-3, -1e-2, "foo" );
test_test("delta_not_within(\$a,\$b,-\$e) fail works");

test_out("ok 1 - foo");
delta_not_within( 1.1e-4, 2e-4, 1e-5, "foo" );
test_test("delta_not_within(\$a,\$b,\$e) pass works");

test_out("ok 1 - foo");
delta_not_within( 1.1e-4, 2e-4, -1e-5, "foo" );
test_test("delta_not_within(\$a,\$b,-\$e) pass works");

#--------------------------------------------------------------------------#
# list - length
#--------------------------------------------------------------------------#

test_out("not ok 1 - foo");
test_fail(+2);
test_diag("Got an array of length 2, but expected an array of length 1");
delta_ok( [ 1e-5, 2e-5 ], [1e-5], "foo" );
test_test("delta_ok(\\\@a,\\\@b) unequal length fail works");

#--------------------------------------------------------------------------#
# list -- delta_ok
#--------------------------------------------------------------------------#

test_out("not ok 1 - foo");
test_fail(+2);
test_diag("At [1]: 0.0000200 and 0.0000300 are not equal to within 0.000001");
delta_ok( [ 1e-5, 2e-5 ], [ 1e-5, 3e-5 ], "foo" );
test_test("delta_ok(\\\@a,\\\@b) pairwise fail works");

test_out("ok 1 - foo");
delta_ok( [ 1e-5, 2e-5 ], [ 1e-5, 2e-5 ], "foo" );
test_test("delta_ok(\\\@a,\\\@b) pairwise pass works");

#--------------------------------------------------------------------------#
# list -- delta_not_ok
#--------------------------------------------------------------------------#

test_out("not ok 1 - foo");
test_fail(+2);
test_diag("Arguments are equal to within 0.000001");
delta_not_ok( [ 1e-7, 2e-7 ], [ 1e-7, 2e-7 ], "foo" );
test_test("delta_not_ok(\\\@a,\\\@b) pairwise fail at [0] works");

test_out("ok 1 - foo");
delta_not_ok( [ 1e-5, 2e-5 ], [ 1e-5, 3e-5 ], "foo" );
test_test("delta_not_ok(\\\@a,\\\@b) pairwise pass works");

#--------------------------------------------------------------------------#
# matrix -- delta_ok
#--------------------------------------------------------------------------#

test_out("not ok 1 - foo");
test_fail(+2);
test_diag("At [1][0]: 0.0000300 and 0.0000100 are not equal to within 0.000001");
delta_ok( [ [ 1e-5, 2e-5 ], [ 3e-5, 4e-5 ] ],
    [ [ 1e-5, 2e-5 ], [ 1e-5, 4e-5 ] ], "foo" );
test_test("delta_ok(\\\@a,\\\@b) matrix fail works");

test_out("ok 1 - foo");
delta_ok( [ [ 1e-5, 2e-5 ], [ 3e-5, 4e-5 ] ],
    [ [ 1e-5, 2e-5 ], [ 3e-5, 4e-5 ] ], "foo" );
test_test("delta_ok(\\\@a,\\\@b) matrix pass works");

#--------------------------------------------------------------------------#
# matrix -- delta_not_ok
#--------------------------------------------------------------------------#

test_out("not ok 1 - foo");
test_fail(+2);
test_diag("Arguments are equal to within 0.000001");
delta_not_ok( [ [ 1e-7, 2e-7 ], [ 3e-7, 4e-7 ] ],
    [ [ 2e-7, 3e-7 ], [ 4e-7, 5e-7 ] ], "foo" );
test_test("delta_not_ok(\\\@a,\\\@b) matrix fail works");

test_out("ok 1 - foo");
delta_not_ok( [ [ 1e-7, 2e-7 ], [ 3e-7, 4e-5 ] ],
    [ [ 5e-7, 6e-7 ], [ 7e-7, 8e-5 ] ], "foo" );
test_test("delta_not_ok(\\\@a,\\\@b) matrix pass works");

#--------------------------------------------------------------------------#
# matrix -- delta_within
#--------------------------------------------------------------------------#

test_out("not ok 1 - foo");
test_fail(+2);
test_diag("At [1][0]: 0.00300 and 0.00100 are not equal to within 0.0001");
delta_within(
    [ [ 1e-3, 2e-3 ], [ 3e-3, 4e-3 ] ],
    [ [ 1e-3, 2e-3 ], [ 1e-3, 4e-3 ] ],
    1e-4, "foo"
);
test_test("delta_within(\\\@a,\\\@b,\$e) matrix fail works");

test_out("ok 1 - foo");
delta_within(
    [ [ 1e-3, 2e-3 ], [ 3e-3, 4e-3 ] ],
    [ [ 1e-3, 2e-3 ], [ 3e-3, 4e-3 ] ],
    1e-4, "foo"
);
test_test("delta_within(\\\@a,\\\@b,\$e) matrix pass works");

#--------------------------------------------------------------------------#
# matrix -- delta_not_within
#--------------------------------------------------------------------------#

test_out("not ok 1 - foo");
test_fail(+2);
test_diag("Arguments are equal to within 0.0001");
delta_not_within(
    [ [ 1e-5, 2e-5 ], [ 3e-5, 4e-5 ] ],
    [ [ 5e-5, 6e-5 ], [ 7e-5, 8e-5 ] ],
    1e-4, "foo"
);
test_test("delta_not_within(\\\@a,\\\@b,\$e) matrix fail works");

test_out("ok 1 - foo");
delta_not_within(
    [ [ 1e-3, 2e-3 ], [ 3e-3, 4e-3 ] ],
    [ [ 5e-3, 6e-3 ], [ 7e-3, 8e-3 ] ],
    1e-4, "foo"
);
test_test("delta_not_within(\\\@a,\\\@b,\$e) matrix pass works");

