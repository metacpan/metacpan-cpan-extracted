use strict;
use warnings;
use utf8;

BEGIN {
    use Test::Builder::Tester;
    use Test::LimitDecimalPlaces tests => 4;
}

limit_ok(
    [ 0, 1, 0.1, 0.0000001, 0.0000001 ],
    [ 0, 1, 0.1, 0.0000001, 0.00000006 ],
    'Test arrays.'
);

limit_ok(
    [ 0, 1, 0.1, 0.0000001, 0.0000001, [ 0, 1, 0.1, 0.0000001, 0.0000001 ] ],
    [ 0, 1, 0.1, 0.0000001, 0.00000006, [ 0, 1, 0.1, 0.0000001, 0.00000006 ] ],
    'Test arrays recursive.'
);

test_out('not ok 1 - Test arrays those differ length.');
test_fail(+2);
test_diag('Got length of an array is 3, but expected length of an array is 4');
limit_ok(
    [ 0.1, 0.2, 0.3 ],
    [ 0.1, 0.2, 0.3, 0.4 ],
    'Test arrays those differ length.'
);
test_test('Test arrays those differ length.');

test_out('not ok 1 - Test arrays those have different value.');
test_fail(+7);
test_diag(
    sprintf("%.7f", 0.3) . ' and ' .
    sprintf("%.7f", 0.5) .
    ' are not equal by limiting decimal places is 7,' .
    ' number of element is 2 in array'
);
limit_ok(
    [0.1, 0.2, 0.3, 0.4],
    [0.1, 0.2, 0.5, 0.4],
    'Test arrays those have different value.'
);
test_test('Test arrays those have different value.');
