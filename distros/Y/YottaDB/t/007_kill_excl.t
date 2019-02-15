use strict;
use warnings;

use Test::More tests => 4;
use YottaDB qw/:all/;
ok(1);

y_set "a", 1;
y_set "b", 2;
y_set "c", 3;

y_kill_excl ("a", "c", "x");

ok (0 == y_data ("b"));
ok (1 == y_data ("a"));
ok (1 == y_data ("c"));
