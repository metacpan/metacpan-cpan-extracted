
use strict;
use Test::More tests => 2;

BEGIN { use_ok('Test::Timer'); }

time_atmost( sub { sleep(1); }, 2, 'Passing test' );
