use strict;
use warnings;
use Test::More;

use FindBin qw($Bin);
use lib "$Bin/../t";

use Test::Timer::Test qw(_sleep);

use_ok('Test::Timer');

time_between( sub { _sleep(1); }, 0, 10, 'Returning between 1 and 10 seconds' );

done_testing();
