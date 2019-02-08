use strict;
use warnings;

use UV::Loop ();

use Test::More;

# are all of the UV::Loop functions exportable as we expect?
can_ok('UV::Loop', (
    qw(UV_RUN_DEFAULT UV_RUN_ONCE UV_RUN_NOWAIT UV_LOOP_BLOCK_SIGNAL SIGPROF),
    qw(new default default_loop on alive backend_fd backend_timeout configure),
    qw(walk now run stop update_time close is_default),
));

done_testing;
