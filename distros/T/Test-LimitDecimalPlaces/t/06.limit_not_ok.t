use strict;
use warnings;
use utf8;

select(STDOUT); $|++;
select(STDERR); $|++;

BEGIN {
    use Test::Builder::Tester;
    use Test::LimitDecimalPlaces num_of_digits => 6, tests => 5;
}

limit_not_ok( 0,   1,    'Test different integer.' );
limit_not_ok( 0.1, 0.01, 'Test different values' );

test_out('not ok 1 - Test same integer.');
test_fail(+5);
test_diag(
        sprintf( "%.6f", 42 ) . ' and '
      . sprintf( "%.6f", 42 )
      . ' are equal by limiting decimal places is 6' );
limit_not_ok( 42, 42, 'Test same integer.' );
test_test('Test same integer.');

test_out('not ok 1 - Test same values.');
test_fail(+5);
test_diag(
        sprintf( "%.6f", 0.1 ) . ' and '
      . sprintf( "%.6f", 0.1 )
      . ' are equal by limiting decimal places is 6' );
limit_not_ok( 0.1, 0.1, 'Test same values.' );
test_test('Test same values.');

test_out('not ok 1 - Test similar values.');
test_fail(+5);
test_diag(
        sprintf( "%.6f", 0.000001 ) . ' and '
      . sprintf( "%.6f", 0.0000006 )
      . ' are equal by limiting decimal places is 6' );
limit_not_ok( 0.000001, 0.0000006, 'Test similar values.' );
test_test('Test similar values.');
