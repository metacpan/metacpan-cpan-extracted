use Test::More tests => 2;

use qbit;

is_deeply(
    [sort @{arrays_intersection([1,2,3,4], [2,3,4,5])}],
    [2,3,4],
    "arrays_intersection: 2 arrays"
);

is_deeply(
    [sort @{arrays_intersection([1,2,3,4], [2,3,4,5], [3,4,5,6,5])}],
    [3,4],
    "arrays_intersection: 3 arrays"
);
