use strict;
use warnings;

use UV::Async ();

use Test::More;

# are all of the UV::Handle functions exportable as we expect?
can_ok('UV::Async', (
    qw(new on close closed loop data),
    qw(active closing),
));

# are the extra methods also available?
can_ok('UV::Async', (
    qw(send),
));

done_testing;
