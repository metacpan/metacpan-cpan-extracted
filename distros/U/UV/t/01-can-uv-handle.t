use strict;
use warnings;

use UV::Handle ();

use Test::More;

# are all of the functions exportable as we expect?
can_ok('UV::Handle', (
    qw(new on close closed loop data),
    qw(active closing has_ref ref unref),
));

done_testing;
