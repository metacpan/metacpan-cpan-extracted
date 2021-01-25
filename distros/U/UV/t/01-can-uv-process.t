use strict;
use warnings;

use UV::Process ();

use Test::More;

# are all of the functions exportable as we expect?
can_ok('UV::Process', (
    qw(spawn on close closed loop data),
    qw(active closing),
));

# are the extra methods also available?
can_ok('UV::Process', (
    qw(kill pid),
));

done_testing;

