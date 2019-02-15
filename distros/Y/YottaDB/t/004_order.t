use strict;
use warnings;

use Test::More tests => 4;
use YottaDB qw/:all/;

ok(1);

y_set "a", 1, 2;
y_set "a",  99, 3;

ok ( 1  == y_next("a", ""));
ok ( 99 == y_next("a", "1"));
ok ( not defined  y_next("a", 99));

