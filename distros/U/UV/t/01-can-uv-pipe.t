use v5.14;
use warnings;

use UV::Pipe ();

use Test::More;

# are all of the UV::Handle functions exportable as we expect?
can_ok('UV::Pipe', (
    qw(new on close closed loop data),
    qw(active closing),
));

# are all of the UV::Stream methods available?
can_ok('UV::Pipe', (
    qw(shutdown listen accept read_start read_stop write),
));

# are the extra methods also available?
can_ok('UV::Pipe', (
    qw(bind connect open getpeername getsockname chmod),
));


done_testing;
