use strict;
use warnings;

use Test::More tests => 2;

use YottaDB qw/:all/;

y_set a => 42;
ok (y_get ("a") == 42);


my @idx = ("eins", "zwei", "drei", "vier");

y_set "a", @idx, 41;
ok (y_get ("a", @idx) == 41);

