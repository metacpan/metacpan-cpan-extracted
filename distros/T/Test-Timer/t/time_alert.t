use strict;
use warnings;
use Test::More;

use_ok('Test::Timer');

time_nok( sub { sleep(10); }, 1, 'Failing test' );

done_testing();
