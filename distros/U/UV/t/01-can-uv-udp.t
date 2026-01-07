use v5.14;
use warnings;

use UV::UDP ();

use Test::More;

# are all of the UV::Handle functions exportable as we expect?
can_ok('UV::UDP', (
    qw(new on close closed loop data),
    qw(active closing),
));

# are the extra methods also available?
can_ok('UV::UDP', (
    qw(open bind connect getpeername getsockname),
    qw(set_broadcast set_ttl get_send_queue_size get_send_queue_count),
    qw(set_multicast_loop set_multicast_ttl set_multicast_interface),
    qw(set_membership set_source_membership),
    qw(recv_start recv_stop send try_send),
));

done_testing;
