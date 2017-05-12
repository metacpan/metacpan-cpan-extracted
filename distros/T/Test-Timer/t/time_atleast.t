
use strict;
use Test::More tests => 2;

BEGIN { use_ok('Test::Timer'); }

time_atleast( sub { sleep(2); }, 1, 'Failing test' );
