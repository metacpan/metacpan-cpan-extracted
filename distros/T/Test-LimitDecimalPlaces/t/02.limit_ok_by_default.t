use strict;
use warnings;
use utf8;

select(STDOUT); $|++;
select(STDERR); $|++;

BEGIN {
    use Test::Builder::Tester;
    use Test::LimitDecimalPlaces tests => 6;
}

limit_ok(0, 0, 'Test zero.');
limit_ok(42, 42, 'Test integer.');
limit_ok(1.2345678, 1.2345678, 'Test the same floating-point values.');
limit_ok(0.12345678, 0.12345678, 'Test the same floating-point values overed limiting num of decimal places.');
limit_ok(0.0000001, 0.00000006, 'Test similar values.');

test_out('not ok 1 - Test different values.');
test_fail(+5);
test_diag(
        sprintf( "%.7f", 0.0000001 ) . ' and '
      . sprintf( "%.7f", 0.00000001 )
      . ' are not equal by limiting decimal places is 7' );
limit_ok(0.0000001, 0.00000001, 'Test different values.');
test_test('Test different values.');
