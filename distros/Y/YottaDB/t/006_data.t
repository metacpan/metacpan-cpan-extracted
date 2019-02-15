use strict;
use warnings;

use Test::More tests => 5;
use YottaDB qw/:all/;
ok(1);

y_set "a", 1, 2;
y_set "a", 2, 2;
y_set "a", 2, 2, 3;
y_set "a", "5", "5", "5";
ok (  0 == y_data("doesntexist"));
ok (  1 ==  y_data("a", 1));
ok ( 10 ==  y_data("a", 5));
ok ( 11 ==  y_data("a", 2));

