use v5.14;
use warnings;

use UV::Signal ();

use Test::More;

# are all of the UV::Handle functions exportable as we expect?
can_ok('UV::Signal', (
    qw(new on close closed loop data),
    qw(active closing),
));

# are the extra methods also available?
can_ok('UV::Signal', (
    qw(start stop),
));


done_testing;
