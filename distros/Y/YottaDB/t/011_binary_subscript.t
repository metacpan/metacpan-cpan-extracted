use strict;
use warnings;

use Test::More tests => 1;
use YottaDB qw/:all/;

$a .= chr($_) for (0..127);

y_set "a", $a, $a;

$b = y_get "a", $a;

ok ($a eq $b);
