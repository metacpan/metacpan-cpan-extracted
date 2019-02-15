use strict;
use warnings;

use Test::More tests => 3;
use YottaDB qw/:all/;
ok(1);

y_set "a", 1, 2;
y_set "a",  99, 3;

ok ( 99  == y_previous("a", ""));
ok ( 1 == y_previous("a", "99"));

