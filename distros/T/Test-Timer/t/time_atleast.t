use strict;
use warnings;
use Test::More;

use_ok('Test::Timer');

time_atleast( sub { sleep(2); }, 1, 'Failing test' );

done_testing();
