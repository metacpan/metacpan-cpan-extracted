use strict;
use warnings;

use Test::More tests => 1;
use YottaDB qw/:all/;

$a .= chr($_) for (0..127);

y_set "a", 1, 2, 3, $a;

$b = y_get "a", 1, 2, 3;

ok ($a eq $b);





