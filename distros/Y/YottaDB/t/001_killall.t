use strict;
use warnings;

use Test::More tests => 1;

use YottaDB qw/:all/;

y_killall ();
ok(1);
