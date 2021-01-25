use strict;
use warnings;

use UV::Check ();

use Test::More;

# are all of the UV::Handle functions exportable as we expect?
can_ok('UV::Check', (
    qw(new on close closed loop data),
    qw(active closing),
));

# are the extra methods also available?
can_ok('UV::Check', (
    qw(start stop),
));


done_testing;
