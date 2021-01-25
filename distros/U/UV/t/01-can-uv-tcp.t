use strict;
use warnings;

use UV::TCP ();

use Test::More;

# are all of the UV::Handle functions exportable as we expect?
can_ok('UV::TCP', (
    qw(new on close closed loop data),
    qw(active closing),
));

# are all of the UV::Stream methods available?
can_ok('UV::TCP', (
    qw(shutdown listen accept read_start read_stop write),
));

# are the extra methods also available?
can_ok('UV::TCP', (
    qw(open nodelay keepalive simultaneous_accepts bind connect),
    qw(getpeername getsockname close_reset),
));

done_testing;
