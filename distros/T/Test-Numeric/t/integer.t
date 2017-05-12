use strict;
use warnings;

use Test::Builder::Tester tests => 23;
use Test::More;

# Test using the module.
use Test::Numeric;

# is_integer
foreach my $val qw( -3 0 1 100 1.00 ) {
    ok( Test::Numeric::_test_integer($val), "_test_integer( $val )" )	
	|| diag "Failed test with '$val'";
    is_integer $val;
}

foreach my $val qw( -3.1 0.3 1.001 100.123 ) {
    ok( !Test::Numeric::_test_integer($val), "_test_integer( $val )" )
	|| diag "Failed test with '$val'";
    isnt_integer $val;
}

test_out('ok 1 - integer');
is_integer 1, 'integer';
test_test('is_integer');

test_out('not ok 1 - integer');
test_fail(1);
is_integer 1.5, 'integer';
test_test('is_integer');

test_out('ok 1 - integer');
isnt_integer 1.5, 'integer';
test_test('isnt_integer');

test_out('not ok 1 - integer');
test_fail(1);
isnt_integer 1, 'integer';
test_test('isnt_integer');

test_out('not ok 1 - integer');
test_diag('The value given is not a number - failing test.');
test_fail(1);
isnt_integer 'test', 'integer';
test_test('isnt_integer');

