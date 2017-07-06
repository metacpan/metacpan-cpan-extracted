use strict;
use warnings;
use Test::More;

use Test::Fatal;

use_ok('Test::Timer');

time_ok( sub { sleep(1); }, 2, 'Passing test' );

done_testing();
