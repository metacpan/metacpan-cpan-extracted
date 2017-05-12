use strict;
use warnings;
use utf8;

BEGIN {
    use Test::Exception;
    use Test::Builder::Tester;
    use Test::LimitDecimalPlaces tests => 9;
}

limit_ok_by(0, 0, 5, 'Test zero.');
limit_ok_by(42, 42, 5, 'Test integer');
limit_ok_by(1.0, 1.1, 0, 'Test only integer component.');
limit_ok_by(1.23456, 1.23456, 5, 'Test same values.');
limit_ok_by(1.234567, 1.234567, 6, 'Test same values by different limit value.');
limit_ok_by(1.00001, 1.000006, 5, 'Test similar values.');
limit_ok_by(1.000001, 1.0000006, 6, 'Test similar values by different limit value.');
throws_ok { limit_ok_by(1.0, 1.0, -1) }
    qr/Value of limit number of digits must be a number greater than or equal to zero./;

test_out('not ok 1 - Test different values.');
test_fail(+5);
test_diag(
        sprintf( "%.5f", 0.00001 ) . ' and '
      . sprintf( "%.5f", 0.000001 )
      . ' are not equal by limiting decimal places is 5' );
limit_ok_by(0.00001, 0.000001, 5, 'Test different values.');
test_test('Test different values.');
