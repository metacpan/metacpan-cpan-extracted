use strict;
use warnings;

use UV::Timer ();

use Test::More;

# are all of the UV::Handle functions exportable as we expect?
can_ok('UV::Timer', (
    qw(new on close closed loop data),
    qw(active closing has_ref ref unref),
));

# are the extra methods also available?
can_ok('UV::Timer', (
    qw(again repeat start stop),
));


done_testing;
