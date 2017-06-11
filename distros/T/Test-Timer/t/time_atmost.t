
use strict;
use Test::More;

BEGIN { use_ok('Test::Timer'); }

time_atmost( sub { sleep(1); }, 2, 'Passing test' );

done_testing();
