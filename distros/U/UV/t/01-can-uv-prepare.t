use strict;
use warnings;

use UV::Prepare ();

use Test::More;

# are all of the UV::Handle functions exportable as we expect?
can_ok('UV::Prepare', (
    qw(new on close closed loop data),
    qw(active closing),
));

# are the extra methods also available?
can_ok('UV::Prepare', (
    qw(start stop),
));


done_testing;
