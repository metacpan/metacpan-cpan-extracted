use strict;
use warnings;

use Test::More tests => 3;
use YottaDB qw/:all/;

y_set a => 2;

ok (4 == y_incr a => 2);

ok (3 == y_incr a => -1);

ok (42 == y_incr "a", 1, 2, 3, 4, 5, 42);
