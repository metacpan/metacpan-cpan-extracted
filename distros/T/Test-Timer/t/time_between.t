
use strict;
use Test::More tests => 2;

BEGIN { use_ok('Test::Timer'); }

time_between( sub { sleep(1); }, 0, 10, 'Returning between 1 and 10 seconds' );

