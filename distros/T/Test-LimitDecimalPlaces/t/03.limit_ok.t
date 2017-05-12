use strict;
use warnings;
use utf8;

select(STDOUT); $|++;
select(STDERR); $|++;

BEGIN {
    use Test::Builder::Tester;
    use Test::LimitDecimalPlaces num_of_digits => 6, tests => 6;
}

limit_ok(0, 0, 'Test zero.');
limit_ok(42, 42, 'Test integer');
limit_ok(1.234567, 1.234567, 'Test the same floating-point values.');
limit_ok(0.1234567, 0.1234567, 'Test the same floating-point values overed limiting num of decimal places.');
limit_ok(0.000001, 0.0000006, 'Test similar value.');

test_out('not ok 1 - Test different values.');
test_fail(+5);
test_diag(
        sprintf( "%.6f", 0.000001 ) . ' and '
      . sprintf( "%.6f", 0.0000001 )
      . ' are not equal by limiting decimal places is 6' );
limit_ok(0.000001, 0.0000001, 'Test different values.');
test_test('Test different values.');
