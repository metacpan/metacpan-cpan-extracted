use strict;
use warnings;
use utf8;

select(STDOUT); $|++;
select(STDERR); $|++;

BEGIN {
    use Test::Builder::Tester;
    use Test::LimitDecimalPlaces tests => 7;
}

limit_not_ok_by( 0,   1,    6, 'Test different integer.' );
limit_not_ok_by( 0.1, 0.01, 6, 'Test different values.' );

test_out('not ok 1 - Test same integer.');
test_fail(+5);
test_diag(
        sprintf( "%.6f", 42 ) . ' and '
      . sprintf( "%.6f", 42 )
      . ' are equal by limiting decimal places is 6' );
limit_not_ok_by( 42, 42, 6, 'Test same integer.' );
test_test('Test same integer.');

test_out('not ok 1 - Test same values.');
test_fail(+5);
test_diag(
        sprintf( "%.6f", 0.123456 ) . ' and '
      . sprintf( "%.6f", 0.123456 )
      . ' are equal by limiting decimal places is 6' );
limit_not_ok_by( 0.123456, 0.123456, 6, 'Test same values.' );
test_test('Test same values.');

test_out('not ok 1 - Test same values by different limit value.');
test_fail(+5);
test_diag(
        sprintf( "%.5f", 0.12345 ) . ' and '
      . sprintf( "%.5f", 0.12345 )
      . ' are equal by limiting decimal places is 5' );
limit_not_ok_by( 0.12345, 0.12345, 5,
    'Test same values by different limit value.' );
test_test('Test same values by different limit value.');

test_out('not ok 1 - Test similar values.');
test_fail(+5);
test_diag(
        sprintf( "%.6f", 0.000001 ) . ' and '
      . sprintf( "%.6f", 0.0000006 )
      . ' are equal by limiting decimal places is 6' );
limit_not_ok_by( 0.000001, 0.0000006, 6, 'Test similar values.' );
test_test('Test similar values.');

test_out('not ok 1 - Test similar values by different limit value.');
test_fail(+5);
test_diag(
        sprintf( "%.5f", 0.00001 ) . ' and '
      . sprintf( "%.5f", 0.000006 )
      . ' are equal by limiting decimal places is 5' );
limit_not_ok_by( 0.00001, 0.000006, 5,
    'Test similar values by different limit value.' );
test_test('Test similar values by different limit value.');
