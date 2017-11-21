use strict;
use warnings;
use Test::More;

use FindBin qw($Bin);
use lib "$Bin/../t";

use Test::Timer::Test qw(_sleep);

use_ok('Test::Timer');

time_atleast( sub { _sleep(2); }, 1, 'Failing test' );

done_testing();
