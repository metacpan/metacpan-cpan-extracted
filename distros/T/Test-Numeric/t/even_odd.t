use strict;
use warnings;

use Test::Builder::Tester tests => 25;
use Test::More;

# Test using the module.
use_ok 'Test::Numeric';

# Test the tests.

my @even  = qw( -2 0 2 12345678 );
my @odd   = qw( -1 1 3 12345679 );
my @wrong = qw( test 0.5 );

ok( Test::Numeric::_test_even($_),  "trying '$_'" ) for @even;
ok( Test::Numeric::_test_odd($_),   "trying '$_'" ) for @odd;
ok( !Test::Numeric::_test_even($_), "trying '$_'" ) for @odd;
ok( !Test::Numeric::_test_odd($_),  "trying '$_'" ) for @even;
ok( !Test::Numeric::_test_even($_), "trying '$_'" ) for @wrong;
ok( !Test::Numeric::_test_odd($_),  "trying '$_'" ) for @wrong;

# Test the 'is_even' function.
test_out('ok 1 - foo');
is_even( 2, 'foo' );
test_test("is_even");

test_out('not ok 1 - foo');
test_fail(+1);
is_even( 3, 'foo' );
test_test("is_even");

# Test the 'is_odd' function.
test_out('ok 1 - foo');
is_odd( 3, 'foo' );
test_test("is_odd");

test_out('not ok 1 - foo');
test_fail(+1);
is_odd( 4, 'foo' );
test_test("is_odd");

