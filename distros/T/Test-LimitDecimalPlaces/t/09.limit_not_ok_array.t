use strict;
use warnings;
use utf8;

select(STDOUT); $|++;
select(STDERR); $|++;

BEGIN {
    use Test::Builder::Tester;
    use Test::LimitDecimalPlaces tests => 5;
}

limit_not_ok(
    [ 0, 1, 0.1, 0.0000001, 0.0000001 ],
    [ 0, 1, 0.1, 0.0000002, 0.0000001 ],
    'Test different arrays.'
);

limit_not_ok(
    [ 0, 1, 0.1, 0.0000001, 0.0000001, [ 0, 1, 0.1, 0.0000001, 0.0000001 ] ],
    [ 0, 1, 0.1, 0.0000001, 0.0000001, [ 0, 1, 0.1, 0.0000002, 0.0000001 ] ],
    'Test different arrays recursive.'
);

limit_not_ok(
    [ 0, 1, 0.1, 0.0000001, 0.0000001 ],
    [ 0, 1, 0.1, 0.0000001 ],
    'Test different length arrays.'
);

limit_not_ok(
    [ 0, 1, 0.1, 0.0000001, 0.0000001, [ 0, 1, 0.1, 0.0000001, 0.0000001 ] ],
    [ 0, 1, 0.1, 0.0000001, 0.0000001, [ 0, 1, 0.1, 0.0000001 ] ],
    'Test different length arrays recursive.'
);

test_out('not ok 1 - Test same arrays.');
test_fail(+2);
test_diag('Both of arrays are the same.');
limit_not_ok(
    [ 0, 1, 0.1, 0.0000001, 0.0000001 ],
    [ 0, 1, 0.1, 0.0000001, 0.0000001 ],
    'Test same arrays.'
);
test_test('Test same arrays.');
