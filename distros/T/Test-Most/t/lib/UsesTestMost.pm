package UsesTestMost;

use strict;
use warnings;
use Test::Most;

sub is_it_one { ok(shift == 1, "yes it's one") }

1;
