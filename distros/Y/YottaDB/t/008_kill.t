use strict;
use warnings;

use Test::More tests => 3;
use YottaDB qw/:all/;
ok(1);

y_set "a", 1;
y_set "a", 1, 1;
y_set "a", 1, 1, 1;

y_kill_node ("a", 1);

ok (1 == y_get ("a", 1, 1));

y_kill_tree("a", 1);

ok (0 == y_data ("a", 1, 1));
